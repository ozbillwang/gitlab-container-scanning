# frozen_string_literal: true

RSpec.describe 'PhotonOS' do
  context 'when scanning an PhotonOS based image', integration: :photon do
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('photon-Dockerfile').to_s,
        'DOCKER_IMAGE' => 'photon:1.0-20210409',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    let(:project_fixture) { fixture_file('docker/photon_project') }

    include_examples 'as container scanner', unsupported_scanners: [Gcs::Grype]
  end
end
