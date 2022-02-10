# frozen_string_literal: true
RSpec.describe Gcs::Remediations::Remediation do
  let(:docker_file) { fixture_file('docker/remediation-Dockerfile') }
  let(:package_name) { 'something' }
  let(:package_version) { '1.0.0' }
  let(:fixed_version) { '2.2.1' }

  after do
    `git checkout #{docker_file.to_path}`
  end

  RSpec.shared_examples 'remediates Dockerfile' do
    let(:remediation) do
      described_class.new(
        {
          'package_name' => package_name,
          'package_version' => package_version,
          'fixed_version' => fixed_version,
          'operating_system' => operating_system,
          'summary' => "Upgrade #{package_name} to #{fixed_version}"
        },
        docker_file
      )
    end

    before do
      remediation.add_fix('123', '456')
    end

    it 'remediates Dockerfile' do
      expect(remediation.to_hash).to include(
        fixes: [{ 'cve' => '123', 'id' => '456' }],
        summary: "Upgrade #{package_name} to #{fixed_version}",
        diff: diff
      )
    end
  end

  describe 'for multi build docker file' do
    let(:package_name) { 'curl' }
    let(:operating_system) { 'centos' }
    let(:docker_file) { fixture_file('docker/remediation-multibuild-Dockerfile') }

    let(:diff) do
      'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLW11bHRpYnVpbGQtRG9ja2VyZmlsZSBiL' \
      '3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLW11bHRpYnVpbGQtRG9ja2VyZmlsZQppbmRleCBkNTZkY2UxLi' \
      '5mODI0NDdhIDEwMDY0NAotLS0gYS9zcGVjL2ZpeHR1cmVzL2RvY2tlci9yZW1lZGlhdGlvbi1tdWx0aWJ1aWxkLURvY2t' \
      'lcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tbXVsdGlidWlsZC1Eb2NrZXJmaWxlCkBA' \
      'IC02LDYgKzYsNyBAQCBDT1BZIC4gcHJvamVjdAogV09SS0RJUiAvcHJvamVjdAogCiBGUk9NIGNlbnRvczpjZW50b3M4C' \
      'itSVU4geXVtIC15IGNoZWNrLXVwZGF0ZSB8fCB7IHJjPSQ/OyBbICRyYyAtbmVxIDEwMCBdICYmIGV4aXQgJHJjOyB5dW0' \
      'gdXBkYXRlIC15IGN1cmw7IH0gJiYgeXVtIGNsZWFuIGFsbAogRU5WIFBBVEg9Ii9ob21lL2dpdGxhYjoke1BBVEh9IgogQ' \
      '09QWSAtLWZyb209YnVpbGRlciAvcHJvamVjdCAgL2hvbWUvZ2l0bGFiLwogUlVOIHl1bSBpbnN0YWxsIC15IGNhLWNlcnR' \
      'pZmljYXRlcyBnaXQtY29yZSB4eiBydWJ5'
    end

    include_examples 'remediates Dockerfile'
  end

  describe 'for single build docker file' do
    context 'when using the apt package manager' do
      where(:operating_system) { %w[debian ubuntu] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCmluZGV4IDA3YjJmZDUuLjFjN2VmNGMgMTAwNjQ0Ci0tLSBhL3NwZWMv' \
        'Zml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRp' \
        'YXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUgQEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiBh' \
        'cHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IHVwZ3JhZGUgLXkgc29tZXRoaW5nICYmIHJtIC1yZiAvdmFyL2xpYi9hcHQvbGlz' \
        'dHMvKgogUlVOIGFwdC1nZXQgdXBkYXRlICYmIGFwdC1nZXQgaW5zdGFsbCAteSAtcSBcCiAgIHdnZXQgXAogICBnaXQ='
      end

      with_them { include_examples 'remediates Dockerfile' }
    end

    context 'when using the yum package manager' do
      where(:operating_system) { %w[amazon centos oracle redhat rhel rocky alma amzn ol] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCmluZGV4IDA3YjJmZDUuLjhmYmQyNDkgMTAwNjQ0Ci0tLSBhL3NwZWMv' \
        'Zml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRp' \
        'YXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUgQEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiB5' \
        'dW0gLXkgY2hlY2stdXBkYXRlIHx8IHsgcmM9JD87IFsgJHJjIC1uZXEgMTAwIF0gJiYgZXhpdCAkcmM7IHl1bSB1cGRhdGUg' \
        'LXkgc29tZXRoaW5nOyB9ICYmIHl1bSBjbGVhbiBhbGwKIFJVTiBhcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3RhbGwg' \
        'LXkgLXEgXAogICB3Z2V0IFwKICAgZ2l0'
      end

      with_them { include_examples 'remediates Dockerfile' }
    end

    context 'when using the tndf package manager' do
      where(:operating_system) { %w[photon] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCmluZGV4IDA3YjJmZDUuLmE4MGE5ZDUgMTAwNjQ0Ci0tLSBhL3NwZWMv' \
        'Zml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRp' \
        'YXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUgQEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiB0' \
        'ZG5mIC15IGNoZWNrLXVwZGF0ZSB8fCB7IHJjPSQ/OyBbICRyYyAtbmVxIDEwMCBdICYmIGV4aXQgJHJjOyB0ZG5mIHVwZGF0' \
        'ZSAteSBzb21ldGhpbmc7IH0gJiYgdGRuZiBjbGVhbiBhbGwKIFJVTiBhcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3Rh' \
        'bGwgLXkgLXEgXAogICB3Z2V0IFwKICAgZ2l0'
      end

      with_them { include_examples 'remediates Dockerfile' }
    end

    context 'when using the zypper package manager' do
      where(:operating_system) { %w[opensuse opensuseleap opensuse.leap] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCmluZGV4IDA3YjJmZDUuLmM5NmRjZDMgMTAwNjQ0Ci0tLSBhL3NwZWMv' \
        'Zml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRp' \
        'YXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUgQEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiB6' \
        'eXBwZXIgcmVmIC0tZm9yY2UgJiYgenlwcGVyIGluc3RhbGwgLXkgLS1mb3JjZSBzb21ldGhpbmc9Mi4yLjEKIFJVTiBhcHQt' \
        'Z2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3RhbGwgLXkgLXEgXAogICB3Z2V0IFwKICAgZ2l0' \
      end

      with_them { include_examples 'remediates Dockerfile' }
    end
  end

  describe 'for unsupported operating systems' do
    let(:remediation) do
      described_class.new(
        {
          'package_name' => 'apt',
          'package_version' => '1.0.0',
          'fixed_version' => '2.2.1',
          'operating_system' => 'some-unrecognized-os',
          'summary' => 'Upgrade apt to 2.2.1'
        },
        docker_file
      )
    end

    it 'does not crash' do
      expect(remediation.to_hash).to eq({})
    end
  end
end
