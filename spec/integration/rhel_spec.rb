# frozen_string_literal: true

RSpec.describe 'rhel' do
  context 'when scanning an rhel based image', integration: :rhel do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('rhel-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'registry.access.redhat.com/rhel7:7.9-333',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/rhel_project') }

    include_examples 'as container scanner'
  end
end
