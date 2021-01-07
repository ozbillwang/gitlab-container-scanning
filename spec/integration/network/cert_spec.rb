# frozen_string_literal: true

RSpec.describe 'alpine' do
  context 'when scanning an Alpine based image', integration: true do
    include_examples 'as container scanner'

    let(:env) do
      {
        'ADDITIONAL_CA_CERT_BUNDLE' => x509_certificate.read,
        'DOCKER_IMAGE' => 'docker.test/alpine:latest',
      }
    end
  end
end
