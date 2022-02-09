# frozen_string_literal: true

RSpec.describe 'ubuntu' do
  context 'when scanning an ubuntu based image', integration: :ubuntu do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('ubuntu-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'ubuntu:bionic-20210222',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/ubuntu_project') }

    include_examples 'as container scanner'
  end
end
