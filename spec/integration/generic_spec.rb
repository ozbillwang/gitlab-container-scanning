# frozen_string_literal: true

integration_test_image = ENV.fetch('INTEGRATION_TEST_IMAGE', '')
integration_test = integration_test_image.split(':').first

RSpec.describe integration_test do
  context "when scanning a #{integration_test} image", integration: :generic do
    let(:env) { { 'CS_IMAGE' => integration_test_image, 'GITLAB_FEATURES' => '' } }

    context 'when CE' do
      include_examples 'as container scanner'
    end

    context 'when EE' do
      let(:env) { super().merge('GITLAB_FEATURES' => 'container_scanning') }

      include_examples 'as container scanner'

      # we only want to run the integration test for schema v15 against the webgoat image,
      # because running integration tests for both schemas against all images is too slow.
      context 'when CS_SCHEMA_MODEL is set to 15', if: integration_test&.end_with?('webgoat-8.0@sha256') do
        let(:env) { super().merge('CS_SCHEMA_MODEL' => '15') }

        switch_schemas('15.0.4')

        include_examples 'as container scanner'
      end
    end
  end
end
