# frozen_string_literal: true

RSpec.describe 'alpine', integration: true do
  context 'when scanning an Alpine based image' do
    include_examples 'as container scanner'

    let(:env) do
      {
        DOCKERFILE_PATH: project.virtual_path.join('alpine-Dockerfile'),
        DOCKER_IMAGE: 'alpine:latest'
      }
    end
  end
end
