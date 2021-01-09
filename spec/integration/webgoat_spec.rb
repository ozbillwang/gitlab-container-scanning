# frozen_string_literal: true

RSpec.describe 'Webgoat' do
  context "when scanning a Webgoat image", integration: true do
    include_examples "as container scanner"

    let(:project_fixture) { fixture_file('docker/webgoat_project') }
    let(:env) do
      {
        'DOCKERFILE_PATH' => runner.project_path.join('webgoat-Dockerfile').to_s,
        'DOCKER_IMAGE' => "registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e"
      }
    end
  end
end
