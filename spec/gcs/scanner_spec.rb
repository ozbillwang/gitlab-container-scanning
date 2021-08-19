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
