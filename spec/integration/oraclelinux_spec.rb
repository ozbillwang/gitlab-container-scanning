# frozen_string_literal: true

RSpec.describe 'Oracle Linux' do
  context 'when scanning an oraclelinux based image', integration: :oraclelinux do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('oraclelinux-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'oraclelinux:8.2',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/oraclelinux_project') }

    include_examples 'as container scanner'
  end
end
