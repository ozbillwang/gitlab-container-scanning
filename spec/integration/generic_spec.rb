# frozen_string_literal: true

scanner_name = ENV.fetch('SCANNER', 'trivy')

integration_test_image = ENV.fetch('INTEGRATION_TEST_IMAGE', '')
integration_test = integration_test_image.split(':').first

UNSUPPORTED_IMAGES = {
  'trivy' => [],
  'grype' => [
    'opensuse/leap',
    'photon'
  ]
}

RSpec.describe integration_test do
  context "when scanning a #{integration_test} image", integration: :generic do
    let(:env) { { 'DOCKER_IMAGE' => integration_test_image } }

    include_examples 'as container scanner' unless UNSUPPORTED_IMAGES[scanner_name].include?(integration_test)
  end
end
