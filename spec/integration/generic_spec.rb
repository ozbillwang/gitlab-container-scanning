# frozen_string_literal: true

integration_test_image = ENV.fetch('INTEGRATION_TEST_IMAGE', '')
integration_test = integration_test_image.split(':').first

RSpec.describe integration_test do
  context "when scanning a #{integration_test} image", integration: :generic do
    context 'when CE' do
      let(:env) { { 'CS_IMAGE' => integration_test_image, 'GITLAB_FEATURES' => '' } }

      include_examples 'as container scanner'
    end

    context 'when EE', unless: %w[alpine oraclelinux].include?(integration_test) do
      let(:env) { { 'CS_IMAGE' => integration_test_image, 'GITLAB_FEATURES' => 'container_scanning' } }

      include_examples 'as container scanner'
    end
  end
end
