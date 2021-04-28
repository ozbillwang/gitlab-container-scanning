# frozen_string_literal: true
RSpec.describe Gcs::Remediation do
  let(:multi_build_docker_file_path) { fixture_file('docker/remediation-multibuild-Dockerfile') }
  let(:docker_file_path) { fixture_file('docker/remediation-Dockerfile') }

  after do
    if ENV['CI_SERVER'].nil?
      `git checkout #{multi_build_docker_file_path.to_path}`
      `git checkout #{docker_file_path.to_path}`
    end
  end

  describe 'for multi build docker file' do
    let(:remediation) do
      described_class.new(
        {
          'package_name' => 'curl',
          'package_version' => '2.0.0',
          'fixed_version' => '2.2.1',
          'operating_system' => 'centos',
          'summary' => 'Upgrade curl to 2.2.1'
        },
        multi_build_docker_file_path
      )
    end

    it 'remediatiates multi build docker file' do
      remediation.add_fix('123', '456')
      expected_diff = 'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLW11bHRpYnVpbGQtRG9ja2VyZmlsZSBiL' \
                      '3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLW11bHRpYnVpbGQtRG9ja2VyZmlsZQppbmRleCBkNTZkY2UxLi' \
                      '5mODI0NDdhIDEwMDY0NAotLS0gYS9zcGVjL2ZpeHR1cmVzL2RvY2tlci9yZW1lZGlhdGlvbi1tdWx0aWJ1aWxkLURvY2t' \
                      'lcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tbXVsdGlidWlsZC1Eb2NrZXJmaWxlCkBA' \
                      'IC02LDYgKzYsNyBAQCBDT1BZIC4gcHJvamVjdAogV09SS0RJUiAvcHJvamVjdAogCiBGUk9NIGNlbnRvczpjZW50b3M4C' \
                      'itSVU4geXVtIC15IGNoZWNrLXVwZGF0ZSB8fCB7IHJjPSQ/OyBbICRyYyAtbmVxIDEwMCBdICYmIGV4aXQgJHJjOyB5dW0' \
                      'gdXBkYXRlIC15IGN1cmw7IH0gJiYgeXVtIGNsZWFuIGFsbAogRU5WIFBBVEg9Ii9ob21lL2dpdGxhYjoke1BBVEh9IgogQ' \
                      '09QWSAtLWZyb209YnVpbGRlciAvcHJvamVjdCAgL2hvbWUvZ2l0bGFiLwogUlVOIHl1bSBpbnN0YWxsIC15IGNhLWNlcnR' \
                      'pZmljYXRlcyBnaXQtY29yZSB4eiBydWJ5'
      expect(remediation.to_hash).to include(
        fixes: [{ 'cve' => '123', 'id' => '456' }],
        summary: 'Upgrade curl to 2.2.1',
        diff: expected_diff
      )
    end
  end

  describe 'for single build docker file' do
    let(:remediation) do
      described_class.new(
        {
          'package_name' => 'apt',
          'package_version' => '1.0.0',
          'fixed_version' => '2.2.1',
          'operating_system' => 'debian',
          'summary' => 'Upgrade apt to 2.2.1'
        },
        docker_file_path
      )
    end

    it 'remediatiates docker file' do
      remediation.add_fix('123', '456')
      expected_diff = 'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1c' \
                      'mVzL2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCmluZGV4IDA3YjJmZDUuLjk4NDU1MzYgMTAwNjQ0Ci0tLSBhL3' \
                      'NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXI' \
                      'vcmVtZWRpYXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUgQEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxk' \
                      'ZXIKK1JVTiBhcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IHVwZ3JhZGUgLXkgYXB0ICYmIHJtIC1yZiAvdmFyL2xpYi9hc' \
                      'HQvbGlzdHMvKgogUlVOIGFwdC1nZXQgdXBkYXRlICYmIGFwdC1nZXQgaW5zdGFsbCAteSAtcSBcCiAgIHdnZXQgXAogIC' \
                      'BnaXQ='
      expect(remediation.to_hash).to include(
        fixes: [{ 'cve' => '123', 'id' => '456' }],
        summary: 'Upgrade apt to 2.2.1',
        diff: expected_diff
      )
    end
  end
end
