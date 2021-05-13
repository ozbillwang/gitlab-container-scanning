# frozen_string_literal: true

RSpec.describe 'centos' do
  context 'when scanning an Centos based image', integration: :centos do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('centos8-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'centos:centos8',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => ''
      }
    end

    let(:project_fixture) { fixture_file('docker/centos_project') }

    include_examples 'as container scanner'
  end
end
