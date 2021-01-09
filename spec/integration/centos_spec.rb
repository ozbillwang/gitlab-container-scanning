# frozen_string_literal: true

RSpec.describe 'centos' do
  context 'when scanning an Centos based image', integration: true do
    include_examples 'as container scanner'

    let(:project_fixture) { fixture_file('docker/centos_project') }
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('centos8-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'centos:centos8'
      }
    end
  end
end
