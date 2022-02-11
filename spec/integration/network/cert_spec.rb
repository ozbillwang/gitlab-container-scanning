# frozen_string_literal: true

RSpec.describe 'alpine' do
  before(:all) do
    setup_schemas!
  end

  context 'when scanning an Alpine based image', integration: :ca_cert do
    subject(:report) { runner.report_for(type: 'container-scanning') }

    let(:env) do
      {
        'ADDITIONAL_CA_CERT_BUNDLE' => x509_certificate.read,
        'DOCKER_IMAGE' => 'docker.test/library/alpine:latest',
        'DOCKER_USER' => '',
        'DOCKER_PASSWORD' => '',
        'CS_DISABLE_DEPENDENCY_LIST' => 'false'
      }
    end

    before(:all) do
      runner.mount(env: env)
      runner.scan(env: env)
    end

    specify { expect(report).to match_schema(:container_scanning) }
  end
end
