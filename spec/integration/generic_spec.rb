# frozen_string_literal: true

integration_test_image = ENV.fetch('INTEGRATION_TEST_IMAGE', '')
integration_test = integration_test_image.split(':').first

RSpec.describe integration_test do
  context "when scanning a #{integration_test} image", integration: :generic do
    let(:env) { { 'DOCKER_IMAGE' => integration_test_image, 'GITLAB_FEATURES' => '' } }

    include_examples 'as container scanner'
  end
end
