# frozen_string_literal: true

RSpec.describe 'ubi' do
  context 'when scanning an ubi based image', integration: :ubi do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('ubi-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'redhat/ubi8:8.2-299',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/ubi_project') }

    include_examples 'as container scanner'
  end
end
