# frozen_string_literal: true

RSpec.describe 'Rocky Linux' do
  context 'when scanning an Rocky Linux based image', integration: :rockylinux do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('rockylinux-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'rockylinux:8.5',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/rockylinux_project') }

    include_examples 'as container scanner'
  end
end
