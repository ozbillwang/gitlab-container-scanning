# frozen_string_literal: true

RSpec.describe 'Amazon Linux' do
  context 'when scanning an amazonlinux based image', integration: :amazonlinux do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('amazonlinux-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'amazonlinux:2.0.20201218.1',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/amazonlinux_project') }

    include_examples 'as container scanner'
  end
end
