# frozen_string_literal: true

RSpec.describe 'Distroless' do
  context 'when scanning an distroless based image', integration: :distroless do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('distroless-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'gcr.io/distroless/base-debian9:latest',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/distroless_project') }

    include_examples 'as container scanner'
  end
end
