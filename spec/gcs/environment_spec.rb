# frozen_string_literal: true
RSpec.describe Gcs::Environment do
  let(:commit_sha) { '85cbadce93fec0d78225fc00897221d8a74cb1f9' }
  let(:ci_registry_image) { 'registry.gitlab.com/defen/trivy-test' }
  let(:ci_commit_ref_slug) { 'master' }
  let(:custom_docker_file_path) { 'CustomDocker' }
  let(:docker_file_path) { "#{described_class.project_dir}/Dockerfile" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  describe '.default_docker_image' do
    it 'uses given DOCKER_IMAGE env variable' do
      allow(ENV).to receive(:[]).with('DOCKER_IMAGE').and_return('alpine:latest')

      expect(described_class.default_docker_image).to eq('alpine:latest')
    end

    it 'uses CI_APPLICATION_REPOSITORY and CI_APPLICATION_TAG when DOCKER_IMAGE env variable is not given' do
      allow(ENV).to receive(:fetch).with('CI_APPLICATION_REPOSITORY').and_return('ghcr.io/aquasecurity/trivy')
      allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_return('latest')

      expect(described_class.default_docker_image).to eq('ghcr.io/aquasecurity/trivy:latest')
    end

    it 'uses CI_REGISTRY_IMAGE and CI_COMMIT_REF_SLUG when CI_APPLICATION_REPOSITORY is empty' do
      allow(ENV).to receive(:fetch).with('CI_COMMIT_REF_SLUG').and_return(ci_commit_ref_slug)
      allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
      allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_return('latest')

      expect(described_class.default_docker_image).to eq('registry.gitlab.com/defen/trivy-test/master:latest')
    end

    it 'uses CI_COMMIT_SHA when CI_APPLICATION_REPOSITORY is empty' do
      allow(ENV).to receive(:fetch).with('CI_COMMIT_REF_SLUG').and_return(ci_commit_ref_slug)
      allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
      allow(ENV).to receive(:fetch).with('CI_COMMIT_SHA').and_return(commit_sha)
      image = 'registry.gitlab.com/defen/trivy-test/master:85cbadce93fec0d78225fc00897221d8a74cb1f9'

      expect(described_class.default_docker_image).to eq(image)
    end

    describe '#severity_level' do
      it 'returns value for given severity level' do
        allow(ENV).to receive(:[]).with('CS_SEVERITY_THRESHOLD').and_return('low')

        expect(described_class.severity_level).to eq(1)
      end
    end

    context 'with dockerfile present' do
      before do
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)
      end

      it 'uses dockerfile path variable for remediations' do
        allow(ENV).to receive(:fetch).with('DOCKERFILE_PATH', docker_file_path).and_return(custom_docker_file_path)
        expect(described_class.docker_file.to_s).to eq(custom_docker_file_path)
      end

      it 'uses default value for dockerfile path' do
        expect(described_class.docker_file.to_s).to eq(docker_file_path)
      end
    end

    context 'with dockerfile not present' do
      before do
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
      end

      it 'does not process the remediations', pending: 'What should be the expected behavior here?' do
        expect(Gcs.logger).to receive(:error)
        expect(described_class.docker_file.exist?).to be false
      end
    end

    xit 'exists the program when variables not set' do
      expect(Gcs.logger).to receive(:error)
      execution = -> { described_class.default_docker_image }
      expect(execution).to terminate.with_code(1)
    end
  end

  describe '#setup_environment' do
    subject { described_class.setup_trivy_docker_registry }

    describe 'credentials' do
      before do
        allow(ENV).to receive(:fetch).with('DOCKER_USER').and_return(user)
        allow(ENV).to receive(:fetch).with('DOCKER_PASSWORD').and_return(password)

        ENV['TRIVY_USERNAME'] = ENV['TRIVY_PASSWORD'] = nil
      end

      context 'with credentials configured' do
        let(:user) { 'some user' }
        let(:password) { 'a password' }

        it 'sets Trivy credentials to given values' do
          subject

          expect(ENV['TRIVY_USERNAME']).to eq(user)
          expect(ENV['TRIVY_PASSWORD']).to eq(password)
        end
      end

      context 'with either user or password missing' do
        let(:user) { nil }
        let(:password) { nil }

        it 'continues execution when DOCKER_USER is not set' do
          subject

          expect(ENV['TRIVY_USERNAME']).to eq(nil)
          expect(ENV['TRIVY_PASSWORD']).to eq(nil)
        end
      end
    end

    describe 'insecure registry' do
      before do
        allow(ENV).to receive(:fetch).with('CS_DOCKER_INSECURE', 'false').and_return(docker_insecure)
        allow(ENV).to receive(:fetch).with('CS_REGISTRY_INSECURE', 'false').and_return(registry_insecure)

        ENV['TRIVY_INSECURE'] = ENV['TRIVY_NON_SSL'] = nil
      end

      context 'with insecure docker enabled' do
        let(:docker_insecure) { 'true' }
        let(:registry_insecure) { 'false' }

        it 'sets Trivy TRIVY_INSECURE variable to true' do
          subject

          expect(ENV['TRIVY_INSECURE']).to eq('true')
          expect(ENV['TRIVY_NON_SSL']).to eq('false')
        end
      end

      context 'with insecure registry enabled' do
        let(:docker_insecure) { 'false' }
        let(:registry_insecure) { 'true' }

        it 'sets Trivy TRIVY_NON_SSL variable to true' do
          subject

          expect(ENV['TRIVY_INSECURE']).to eq('false')
          expect(ENV['TRIVY_NON_SSL']).to eq('true')
        end
      end

      context 'with either docker_insecure or registry_insecure are missing' do
        let(:docker_insecure) { nil }
        let(:registry_insecure) { nil }

        it 'does not set trivy variables' do
          subject

          expect(ENV['TRIVY_INSECURE']).to eq(nil)
          expect(ENV['TRIVY_NON_SSL']).to eq(nil)
        end
      end
    end

    describe 'setting up the log level' do
      using RSpec::Parameterized::TableSyntax

      around do |example|
        old_logger_level = Gcs.logger.level

        example.run
      ensure
        Gcs.logger.level = old_logger_level
      end

      where(:log_level, :trivy_debug) do
        'debug'  | 'true'
        'info'   | nil
        'warn'   | nil
        'error'  | nil
        'fatal'  | nil
      end

      with_them do
        before do
          allow(ENV).to receive(:fetch).with('SECURE_LOG_LEVEL', 'info').and_return(log_level)

          described_class.setup_log_level
        end

        it 'sets the Gcs logger level' do
          expect(Gcs.logger.public_send("#{log_level}?")).to be_truthy
        end

        it 'sets the `TRIVY_DEBUG` environment variable correctly' do
          expect(ENV['TRIVY_DEBUG']).to eq(trivy_debug)
        end
      end
    end

    it 'returns current directory if given project path doesn\'t exists' do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return('gitlab/my_project')
      expect(described_class.project_dir).to eq(Pathname.pwd)
    end
  end

  describe '.allow_list_file_path' do
    it 'returns allow list file within the project path' do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return('gitlab/my_project')
      expect(described_class.allow_list_file_path).to eq("#{Pathname.pwd}/vulnerability-allowlist.yml")
    end
  end

  describe '.scanner' do
    context 'without SCANNER' do
      it 'returns GCS::Trivy' do
        expect(described_class.scanner.new).to be_an_instance_of Gcs::Trivy
      end
    end

    context 'with an invalid SCANNER' do
      before do
        allow(ENV).to receive(:fetch).with('SCANNER', 'trivy').and_return('clair')
      end

      it 'throws an error' do
        expect { described_class.scanner }.to raise_error(SystemExit)
      end
    end
  end
end
