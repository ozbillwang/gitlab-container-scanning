# frozen_string_literal: true

RSpec.describe 'alpine' do
  context 'when scanning an Alpine based image', :integration do
    subject { runner.report_for(type: 'container-scanning') }

    before(:all) do
      runner.mount(dir: fixture_file('docker/alpine_project'))
      runner.scan(
        env: {
          'ADDITIONAL_CA_CERT_BUNDLE' => x509_certificate.read,
          'DOCKER_IMAGE' => 'docker.test/library/alpine:latest'
        }
      )
    end

    specify { expect(subject).to match_schema(:container_scanning) }
  end
end
