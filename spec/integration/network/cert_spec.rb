# frozen_string_literal: true

RSpec.describe 'ca cert' do
  before(:all) do
    setup_schemas!
  end

  context 'when scanning an image with ca certificate bundle', integration: :ca_cert do
    subject(:report) { runner.report_for(type: 'container-scanning') }

    before(:all) do
      runner.mount(env: { 'CS_IMAGE' => 'alpine:3.12.0' })
      runner.scan(
        env: {
          'ADDITIONAL_CA_CERT_BUNDLE' => x509_certificate.read,
          'CS_IMAGE' => 'docker.test/library/alpine:3.12.0',
          'CS_REGISTRY_USER' => '',
          'CS_REGISTRY_PASSWORD' => '',
          'CS_DISABLE_DEPENDENCY_LIST' => 'false'
        }
      )
    end

    specify { expect(report).to match_schema(:container_scanning) }
  end
end
