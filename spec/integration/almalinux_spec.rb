# frozen_string_literal: true

RSpec.describe 'AlmaLinux' do
  context 'when scanning an AlmaLinux based image', integration: :almalinux do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('almalinux-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'almalinux:8.5',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/almalinux_project') }

    include_examples 'as container scanner'
  end
end
