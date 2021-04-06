RSpec.describe Gcs::Environment do
  let(:commit_sha) { '85cbadce93fec0d78225fc00897221d8a74cb1f9' }
  let(:ci_registry_image) { 'registry.gitlab.com/defen/trivy-test' }
  let(:ci_commit_ref_slug) { 'master' }
  let(:docker_file_path) { 'CustomDocker' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  it 'uses given DOCKER_IMAGE env variable' do
    allow(ENV).to receive(:[]).with('DOCKER_IMAGE').and_return('alpine:latest')

    expect(Gcs::Environment.default_docker_image).to eq('alpine:latest')
  end

  it 'uses CI_APPLICATION_REPOSITORY and CI_APPLICATION_TAG when DOCKER_IMAGE env variable is not given' do
    allow(ENV).to receive(:fetch).with('CI_APPLICATION_REPOSITORY').and_return('ghcr.io/aquasecurity/trivy')
    allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_return('latest')

    expect(Gcs::Environment.default_docker_image).to eq('ghcr.io/aquasecurity/trivy:latest')
  end

  it 'uses CI_REGISTRY_IMAGE and CI_COMMIT_REF_SLUG when CI_APPLICATION_REPOSITORY is empty' do
    allow(ENV).to receive(:fetch).with('CI_COMMIT_REF_SLUG').and_return(ci_commit_ref_slug)
    allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
    allow(ENV).to receive(:fetch).with('CI_APPLICATION_TAG').and_return('latest')

    expect(Gcs::Environment.default_docker_image).to eq('registry.gitlab.com/defen/trivy-test/master:latest')
  end

  it 'uses CI_COMMIT_SHA when CI_APPLICATION_REPOSITORY is empty' do
    allow(ENV).to receive(:fetch).with('CI_COMMIT_REF_SLUG').and_return(ci_commit_ref_slug)
    allow(ENV).to receive(:fetch).with('CI_REGISTRY_IMAGE').and_return(ci_registry_image)
    allow(ENV).to receive(:fetch).with('CI_COMMIT_SHA').and_return(commit_sha)

    expect(Gcs::Environment.default_docker_image).to eq('registry.gitlab.com/defen/trivy-test/master:85cbadce93fec0d78225fc00897221d8a74cb1f9')
  end

  it 'uses dockerfile path variable for remediations' do
    allow(ENV).to receive(:fetch).with('DOCKERFILE_PATH').and_return(docker_file_path)
    allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)

    expect(Gcs::Environment.docker_file).to eq('CustomDocker')
  end

  it 'uses default value for dockerfile path' do
    allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)

    expect(Gcs::Environment.docker_file).to eq('Dockerfile')
  end

  xit 'exists the program when variables not set' do
    expect(Gcs.logger).to receive(:error)
    execution = -> { Gcs::Environment.default_docker_image }
    expect(execution).to terminate.with_code(1)
  end

  xit 'setup log level' do
    allow(ENV).to receive(:fetch).with('SECURE_LOG_LEVEL').and_return('info')
    Gcs::Environment.setup_log_level

    expect(ENV['CONSOLE_LEVEL']).to eq('info')
  end

  it 'returns current directory if given project path doesn\'t exists' do
    allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return('gitlab/my_project')
    expect(Gcs::Environment.project_dir).to eq(Pathname.pwd)
  end

  describe '.allow_list_file_path' do
    it 'returns allow list file within the project path' do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return('gitlab/my_project')
      expect(Gcs::Environment.allow_list_file_path).to eq("#{Pathname.pwd}/vulnerability-allowlist.yml")
    end
  end
end
