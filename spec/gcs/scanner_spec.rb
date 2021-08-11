# frozen_string_literal: true
RSpec.describe Gcs::Scanner do
  let(:image_name) { 'registry.example.com/image' }

  before do
    my_scanner = Class.new(described_class)
    stub_const('MyScanner', my_scanner)
  end

  describe '.template_file' do
    it 'returns a path in template/ based on the class name' do
      expect(MyScanner.template_file).to end_with 'lib/template/myscanner.tpl'
    end
  end

  describe '.scan_image' do
    let(:log_message) { 'Scanning blah blah blah' }
    let(:output_file_name) { 'path/to/gl-report.json' }
    let(:command) { 'scanner -a -b' }
    let(:environment) { { 'ZOOT' => 'pants' } }

    before do
      allow(described_class).to receive(:scan_command).and_return(command)
      allow(described_class).to receive(:log_message).and_return(log_message)
      allow(described_class).to receive(:environment).and_return(environment)
    end

    subject(:scan_image) { MyScanner.scan_image(image_name, output_file_name) }

    it 'logs an execution message before running scan' do
      expect(Gcs.logger).to receive(:info).with(log_message)
      expect(Gcs.shell).to receive(:execute)

      scan_image
    end

    it 'executes the scan_command with correct arguments and environment' do
      expect(Gcs.shell).to receive(:execute).with(command, environment)

      scan_image
    end

    context 'when stderr is present' do
      let(:status) { double }

      before do
        allow(status).to receive(:success?).and_return(true)
        allow(Gcs.shell).to receive(:execute).and_return(['', stderr, status])
      end

      context 'when image is not found' do
        let(:stderr) do
          "unable to initialize a scanner: unable to initialize a docker scanner: 3 errors occurred:" \
          "* unable to inspect the image (invalid_image:500eeeae44f97568feb254f2141a0603668d03a8): " \
          "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?" \
          "* unable to initialize Podman client: no podman socket found: " \
          "stat podman/podman.sock: no such file or directory" \
          "* GET invalid_image: MANIFEST_UNKNOWN: manifest unknown; map[Tag:]"
        end

        it 'returns image not found error message' do
          expected_err = "The image #{image_name} could not be found. " \
          "To change the image being scanned, use the DOCKER_IMAGE environment variable." \
          "For details, see https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables"

          expect(scan_image[1]).to eq(expected_err)
        end
      end

      context 'when credentials are invalid' do
        let(:stderr) do
          "unable to initialize a scanner: unable to initialize a docker scanner: 3 errors occurred:" \
          "* unable to inspect the image (invalid_image:500eeeae44f97568feb254f2141a0603668d03a8): " \
          "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?" \
          "* unable to initialize Podman client: no podman socket found: " \
          "stat podman/podman.sock: no such file or directory" \
          "GET https://gitlab.com/jwt/auth: UNAUTHORIZED: HTTP Basic: Access denied"
        end

        it 'returns invalid credentials error message' do
          expected_err = "The credentials set in DOCKER_USERNAME and DOCKER_PASSWORD are not valid. "\
                         "Please set a valid credentials."

          expect(scan_image[1]).to eq(expected_err)
        end
      end
    end

    context 'when docker file does not exist' do
      it 'informs the user that remediation is disabled' do
        allow(Gcs::Environment).to receive(:docker_file).and_return(Pathname.new('invalid_path'))
        allow(Gcs.shell).to receive(:execute)
        expect(Gcs.logger).to receive(:info).with(log_message)
        expect(Gcs.logger).to receive(:info).with(match(/Remediation is disabled/))

        scan_image
      end
    end
  end

  describe '.log_message' do
    let(:scanner_version) { '0.0.0' }
    let(:db_updated_at) { '2021-07-28' }
    let(:message) do
      <<~HEREDOC
        Scanning container from registry #{image_name} \
        for vulnerabilities with severity level #{Gcs::Environment.severity_level_name} or higher, \
        with gcs #{Gcs::VERSION} and #{MyScanner.name} #{scanner_version}, advisories updated at #{db_updated_at}
      HEREDOC
    end

    before do
      allow(described_class).to receive(:scanner_version).and_return(scanner_version)
      allow(described_class).to receive(:db_updated_at).and_return(db_updated_at)
    end

    it 'returns a formatted message containing the execution parameters' do
      expect(MyScanner.send(:log_message, image_name)).to eq(message)
    end
  end
end
