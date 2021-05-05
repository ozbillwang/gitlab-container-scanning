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
    # rubocop: disable CodeReuse/ActiveRecord
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

      it 'does not process the remediations' do
        expect(Gcs.logger).to receive(:error)
        expect(described_class.docker_file.exist?).to be false
      end
    end

    xit 'exists the program when variables not set' do
      expect(Gcs.logger).to receive(:error)
      execution = -> { described_class.default_docker_image }
      expect(execution).to terminate.with_code(1)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end

  # rubocop: disable CodeReuse/ActiveRecord
  xit 'setup log level' do
    allow(ENV).to receive(:fetch).with('SECURE_LOG_LEVEL').and_return('info')
    described_class.setup_log_level

    expect(ENV['CONSOLE_LEVEL']).to eq('info')
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  it 'returns current directory if given project path doesn\'t exists' do
    allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return('gitlab/my_project')
    expect(described_class.project_dir).to eq(Pathname.pwd)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  describe '.allow_list_file_path' do
    # rubocop: disable CodeReuse/ActiveRecord
    it 'returns allow list file within the project path' do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return('gitlab/my_project')
      expect(described_class.allow_list_file_path).to eq("#{Pathname.pwd}/vulnerability-allowlist.yml")
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end

  describe '.scanner' do
    context 'without SCANNER' do
      it 'returns GCS::Trivy' do
        expect(described_class.scanner.new).to be_an_instance_of Gcs::Trivy
      end
    end

    context 'with an invalid SCANNER' do
      before do
        # rubocop: disable CodeReuse/ActiveRecord
        allow(ENV).to receive(:fetch).with('SCANNER', 'trivy').and_return('clair')
        # rubocop: enable CodeReuse/ActiveRecord
      end

      it 'throws an error' do
        expect { described_class.scanner }.to raise SystemExit
      end
    end
  end
end
