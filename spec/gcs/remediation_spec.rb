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
                      '4zMzYwY2Y0IDEwMDY0NAotLS0gYS9zcGVjL2ZpeHR1cmVzL2RvY2tlci9yZW1lZGlhdGlvbi1tdWx0aWJ1aWxkLURvY2t' \
                      'lcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tbXVsdGlidWlsZC1Eb2NrZXJmaWxlCkBA' \
                      'IC02LDYgKzYsNyBAQCBDT1BZIC4gcHJvamVjdAogV09SS0RJUiAvcHJvamVjdAogCiBGUk9NIGNlbnRvczpjZW50b3M4C' \
                      'it5dW0gLXkgY2hlY2stdXBkYXRlIHx8IHsgcmM9JD87IFsgJHJjIC1uZXEgMTAwIF0gJiYgZXhpdCAkcmM7IHl1bSB1cG' \
                      'RhdGUgLXkgY3VybDsgfSAmJiB5dW0gY2xlYW4gYWxsCiBFTlYgUEFUSD0iL2hvbWUvZ2l0bGFiOiR7UEFUSH0iCiBDT1B' \
                      'ZIC0tZnJvbT1idWlsZGVyIC9wcm9qZWN0ICAvaG9tZS9naXRsYWIvCiBSVU4geXVtIGluc3RhbGwgLXkgY2EtY2VydGlm' \
                      'aWNhdGVzIGdpdC1jb3JlIHh6IHJ1Ynk='
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
                      'mVzL2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCmluZGV4IDA3YjJmZDUuLjA0NTMxMGYgMTAwNjQ0Ci0tLSBhL3' \
                      'NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXI' \
                      'vcmVtZWRpYXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUgQEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxk' \
                      'ZXIKK2FwdC1nZXQgdXBkYXRlICYmIGFwdC1nZXQgdXBncmFkZSAteSBhcHQgJiYgcm0gLXJmIC92YXIvbGliL2FwdC9sa' \
                      'XN0cy8qCiBSVU4gYXB0LWdldCB1cGRhdGUgJiYgYXB0LWdldCBpbnN0YWxsIC15IC1xIFwKICAgd2dldCBcCiAgIGdpdA=='
      expect(remediation.to_hash).to include(
        fixes: [{ 'cve' => '123', 'id' => '456' }],
        summary: 'Upgrade apt to 2.2.1',
        diff: expected_diff
      )
    end
  end
end
