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

  describe '.docker_image' do
    it 'uses given DOCKER_IMAGE env variable' do
      allow(ENV).to receive(:[]).with('DOCKER_IMAGE').and_return('alpine:latest')
      allow(described_class).to receive(:default_docker_image)

      expect(described_class.docker_image).to eq('alpine:latest')
      expect(described_class).not_to have_received(:default_docker_image)
    end

    context 'when DOCKER_IMAGE env variable is not given' do
      it 'returns default_docker_image' do
        allow(ENV).to receive(:[]).with('DOCKER_IMAGE').and_return(nil)
        allow(described_class).to receive(:default_docker_image).and_return(ci_registry_image)

        expect(described_class.docker_image).to eq(ci_registry_image)
        expect(described_class).to have_received(:default_docker_image).once
      end
    end
  end

  describe '.default_docker_image' do
    it 'uses CI_APPLICATION_REPOSITORY and CI_APPLICATION_TAG' do
      allow(ENV).to receive(:fetch).with('CI_APPLICATION_REPOSITORY').and_return('ghcr.io/aquasecurity/trivy')
      allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_return('latest')

      expect(described_class.default_docker_image).to eq('ghcr.io/aquasecurity/trivy:latest')
    end

    context 'when DOCKER_IMAGE and CI_APPLICATION_REPOSITORY are empty' do
      before do
        allow(ENV).to receive(:[]).with('DOCKER_IMAGE').and_return(nil)
        allow(ENV).to receive(:[]).with('CI_APPLICATION_REPOSITORY').and_return(nil)
        allow(ENV).to receive(:fetch).with('CI_COMMIT_REF_SLUG').and_return(ci_commit_ref_slug)
        allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
      end

      it 'uses CI_REGISTRY_IMAGE and CI_COMMIT_REF_SLUG' do
        allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_return('latest')

        expect(described_class.default_docker_image).to eq('registry.gitlab.com/defen/trivy-test/master:latest')
      end

      it 'uses CI_COMMIT_SHA' do
        allow(ENV).to receive(:fetch).with('CI_COMMIT_SHA').and_return(commit_sha)
        image = 'registry.gitlab.com/defen/trivy-test/master:85cbadce93fec0d78225fc00897221d8a74cb1f9'

        expect(described_class.default_docker_image).to eq(image)
      end
    end

    describe '#severity_level_name' do
      it 'returns value for given severity level' do
        allow(ENV).to receive(:[]).with('CS_SEVERITY_THRESHOLD').and_return('low')

        expect(described_class.severity_level_name).to eq("LOW")
      end

      it 'returns unknown for nil value' do
        allow(ENV).to receive(:[]).with('CS_SEVERITY_THRESHOLD').and_return(nil)

        expect(described_class.severity_level_name).to eq("UNKNOWN")
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

    context 'when required variables are not set' do
      before do
        allow(ENV).to receive(:fetch).with('CI_APPLICATION_REPOSITORY').and_yield
        allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_yield
        allow(ENV).to receive(:fetch).with('CI_COMMIT_REF_SLUG').and_return(ci_commit_ref_slug)
        allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
        allow(ENV).to receive(:fetch).with('CI_COMMIT_SHA').and_return(commit_sha)
      end

      where(:missing_variable) { %w[CI_COMMIT_REF_SLUG CI_REGISTRY_IMAGE CI_COMMIT_SHA] }

      with_them do
        it 'exits the program' do
          allow(ENV).to receive(:fetch).with(missing_variable).and_raise(KeyError.new(key: missing_variable))

          expect(Gcs.logger).to receive(:error)
          execution = -> { described_class.default_docker_image }
          expect(execution).to terminate.with_code(1)
        end
      end
    end
  end

  describe '.setup' do
    around do |example|
      old_logger_level = Gcs.logger.level

      example.run
    ensure
      Gcs.logger.level = old_logger_level
    end

    where(:log_level) do
      %w[debug info warn error fatal]
    end

    with_them do
      before do
        allow(ENV).to receive(:fetch).with('SECURE_LOG_LEVEL', 'info').and_return(log_level)

        described_class.setup
      end

      it 'sets the Gcs logger level' do
        expect(Gcs.logger.public_send("#{log_level}?")).to be_truthy
      end
    end
  end

  describe '.project_dir' do
    it 'returns current directory if given project path doesn\'t exists' do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return('gitlab/my_project')
      expect(described_class.project_dir).to eq(Pathname.pwd)
    end
  end

  describe '.docker_registry_credentials' do
    context 'with default CI credentials set' do
      let(:ci_registry_user) { 'some registry user' }
      let(:ci_registry_password) { 'a registry password' }

      before do
        allow(ENV).to receive(:[]).with('DOCKER_USER').and_return(nil)
        allow(ENV).to receive(:[]).with('DOCKER_PASSWORD').and_return(nil)
        allow(ENV).to receive(:[]).with('CI_REGISTRY_USER').and_return(ci_registry_user)
        allow(ENV).to receive(:[]).with('CI_REGISTRY_PASSWORD').and_return(ci_registry_password)
      end

      context 'with Docker credentials not configured' do
        let(:ci_registry) { 'registry.gitlab.example.com' }
        let(:external_registry_image) { "external.#{ci_registry}/some-image" }

        before do
          allow(ENV).to receive(:[]).with('CI_REGISTRY').and_return(ci_registry)
        end

        context 'with Gitlab registry' do
          let(:internal_registry_image) { "#{ci_registry}/some-image" }

          it 'uses default credentials' do
            allow(described_class).to receive(:docker_image).and_return(internal_registry_image)

            credentials = described_class.docker_registry_credentials

            expect(credentials).not_to be_nil
            expect(credentials['username']).to eq(ci_registry_user)
            expect(credentials['password']).to eq(ci_registry_password)
          end
        end

        context 'with an external registry' do
          it 'does not use default credentials' do
            allow(described_class).to receive(:docker_image).and_return(external_registry_image)

            expect(described_class.docker_registry_credentials).to be_nil
          end
        end

        context 'with external registry similar to Gitlab registry' do
          let(:external_similar_registry_image) { "#{ci_registry}.anotherdomain.com/some-image" }

          it 'does not use default credentials' do
            allow(described_class).to receive(:docker_image).and_return(external_similar_registry_image)

            expect(described_class.docker_registry_credentials).to be_nil
          end
        end
      end

      context 'with Docker credentials configured' do
        let(:docker_user) { 'some Docker user' }
        let(:docker_password) { 'a Docker password' }

        before do
          allow(ENV).to receive(:fetch).with('DOCKER_USER').and_return(docker_user)
          allow(ENV).to receive(:fetch).with('DOCKER_PASSWORD').and_return(docker_password)
        end

        it 'returns configured Docker credentials' do
          expect(described_class.docker_registry_credentials).to include({ 'username' => docker_user,
                                                                           'password' => docker_password })
        end
      end
    end

    context 'with default CI credentials missing' do
      before do
        # DOCKER_IMAGE, CI_REGISTRY are needed lest should_use_ci_credentials? skips the code
        allow(ENV).to receive(:[]).with('DOCKER_IMAGE').and_return('registry.example.com/image')
        allow(ENV).to receive(:[]).with('CI_REGISTRY').and_return('registry.example.com')
        allow(ENV).to receive(:[]).with('CI_REGISTRY_USER').and_return(nil)
        allow(ENV).to receive(:[]).with('CI_REGISTRY_PASSWORD').and_return(nil)
      end

      it 'returns nil credentials' do
        expect(described_class.docker_registry_credentials).to eq(nil)
      end
    end
  end

  describe '.scanner' do
    context 'with SCANNER set to trivy' do
      before do
        allow(ENV).to receive(:fetch).with('SCANNER', 'trivy').and_return('trivy')
      end

      it 'returns GCS::Trivy' do
        expect(described_class.scanner.new).to be_an_instance_of Gcs::Trivy
      end
    end

    context 'with SCANNER set to grype' do
      before do
        allow(ENV).to receive(:fetch).with('SCANNER', 'trivy').and_return('grype')
      end

      it 'returns GCS::Grype' do
        expect(described_class.scanner.new).to be_an_instance_of Gcs::Grype
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

  describe '.default_branch_image' do
    before do
      allow(ENV).to receive(:fetch).with('CI_DEFAULT_BRANCH').and_return('main')
      allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
      allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_return('latest')
    end

    context 'when environment variable is set' do
      let(:default_branch_image) { 'alpine:latest' }

      before do
        allow(ENV).to receive(:fetch).with('CS_DEFAULT_BRANCH_IMAGE', nil).and_return(default_branch_image)
      end

      it 'returns the variable value' do
        expect(described_class.default_branch_image).to eq(default_branch_image)
      end
    end

    context 'when environment variable is unset' do
      before do
        allow(ENV).to receive(:fetch).with('CS_DEFAULT_BRANCH_IMAGE', nil).and_return(nil)
      end

      it 'returns name in default format' do
        expect(described_class.default_branch_image).to eq('registry.gitlab.com/defen/trivy-test/main:latest')
      end
    end

    context 'when a required variable is missing' do
      before do
        allow(ENV).to receive(:fetch).with('CI_DEFAULT_BRANCH').and_return('main')
        allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
        allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_yield
        allow(ENV).to receive(:fetch).with('CI_COMMIT_SHA').and_return(commit_sha)
      end

      where(:missing_variable) { %w[CI_DEFAULT_BRANCH CI_REGISTRY_IMAGE CI_COMMIT_SHA] }

      with_them do
        it 'exits the program' do
          allow(ENV).to receive(:fetch).with(missing_variable).and_raise(KeyError.new(key: missing_variable))

          expect(Gcs.logger).to receive(:error)
          execution = -> { described_class.default_branch_image }
          expect(execution).to terminate.with_code(1)
        end
      end
    end
  end
end
