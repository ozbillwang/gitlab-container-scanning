# frozen_string_literal: true

RSpec.describe 'OpenSUSE' do
  context 'when scanning an OpenSUSE Leap based image', integration: :opensuse do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('opensuse-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'opensuse/leap:15.3',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/opensuse_project') }

    include_examples 'as container scanner'
  end
end
