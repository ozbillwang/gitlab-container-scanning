# frozen_string_literal: true

RSpec.describe 'alpine' do
  context 'when scanning an Alpine based image', integration: true do
    include_examples 'as container scanner'

    let(:project_fixture) { fixture_file('docker/alpine_project') }
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('alpine-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'alpine:latest'
      }
    end
  end
end
