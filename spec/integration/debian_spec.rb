# frozen_string_literal: true

RSpec.describe 'docker' do
  context 'when scanning an debian based image', integration: :debian do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('debian-buster-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'debian:buster-2021051',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/debian_project') }

    include_examples 'as container scanner'
  end
end
