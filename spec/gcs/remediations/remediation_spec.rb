# frozen_string_literal: true
RSpec.describe Gcs::Remediations::Remediation do
  let(:docker_file) { fixture_file('docker/remediation-Dockerfile') }
  let(:package_name) { 'something' }
  let(:package_version) { '1.0.0' }
  let(:fixed_version) { '2.2.1' }

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
      '3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLW11bHRpYnVpbGQtRG9ja2VyZmlsZQotLS0gYS9zcGVjL2ZpeH' \
      'R1cmVzL2RvY2tlci9yZW1lZGlhdGlvbi1tdWx0aWJ1aWxkLURvY2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2N' \
      'rZXIvcmVtZWRpYXRpb24tbXVsdGlidWlsZC1Eb2NrZXJmaWxlCkBAIC02LDYgKzYsNyBAQAogV09SS0RJUiAvcHJvamVj' \
      'dAogCiBGUk9NIGNlbnRvczpjZW50b3M4CitSVU4geXVtIC15IGNoZWNrLXVwZGF0ZSB8fCB7IHJjPSQ/OyBbICRyYyAtb' \
      'mVxIDEwMCBdICYmIGV4aXQgJHJjOyB5dW0gdXBkYXRlIC15IGN1cmw7IH0gJiYgeXVtIGNsZWFuIGFsbAogRU5WIFBBVE' \
      'g9Ii9ob21lL2dpdGxhYjoke1BBVEh9IgogQ09QWSAtLWZyb209YnVpbGRlciAvcHJvamVjdCAgL2hvbWUvZ2l0bGFiLwo' \
      'gUlVOIHl1bSBpbnN0YWxsIC15IGNhLWNlcnRpZmljYXRlcyBnaXQtY29yZSB4eiBydWJ5'
    end

    include_examples 'remediates Dockerfile'
  end

  describe 'for single build docker file' do
    context 'when using the apt package manager' do
      where(:operating_system) { %w[debian ubuntu] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCi0tLSBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURv' \
        'Y2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUg' \
        'QEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiBhcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IHVwZ3Jh' \
        'ZGUgLXkgc29tZXRoaW5nICYmIHJtIC1yZiAvdmFyL2xpYi9hcHQvbGlzdHMvKgogUlVOIGFwdC1nZXQgdXBkYXRlICYmIGFw' \
        'dC1nZXQgaW5zdGFsbCAteSAtcSBcCiAgIHdnZXQgXAogICBnaXQ='
      end

      with_them { include_examples 'remediates Dockerfile' }
    end

    context 'when using the yum package manager' do
      where(:operating_system) { %w[amazon centos oracle redhat rhel rocky amzn ol alma] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCi0tLSBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURv' \
        'Y2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUg' \
        'QEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiB5dW0gLXkgY2hlY2stdXBkYXRlIHx8IHsgcmM9JD87' \
        'IFsgJHJjIC1uZXEgMTAwIF0gJiYgZXhpdCAkcmM7IHl1bSB1cGRhdGUgLXkgc29tZXRoaW5nOyB9ICYmIHl1bSBjbGVhbiBh' \
        'bGwKIFJVTiBhcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3RhbGwgLXkgLXEgXAogICB3Z2V0IFwKICAgZ2l0'
      end

      with_them { include_examples 'remediates Dockerfile' }
    end

    context 'when using the tndf package manager' do
      where(:operating_system) { %w[photon] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCi0tLSBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURv' \
        'Y2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUg' \
        'QEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiB0ZG5mIC15IGNoZWNrLXVwZGF0ZSB8fCB7IHJjPSQ/' \
        'OyBbICRyYyAtbmVxIDEwMCBdICYmIGV4aXQgJHJjOyB0ZG5mIHVwZGF0ZSAteSBzb21ldGhpbmc7IH0gJiYgdGRuZiBjbGVh' \
        'biBhbGwKIFJVTiBhcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3RhbGwgLXkgLXEgXAogICB3Z2V0IFwKICAgZ2l0'
      end

      with_them { include_examples 'remediates Dockerfile' }
    end

    context 'when using the zypper package manager' do
      where(:operating_system) { %w[opensuse opensuseleap opensuse.leap] }

      let(:diff) do
        'ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVz' \
        'L2RvY2tlci9yZW1lZGlhdGlvbi1Eb2NrZXJmaWxlCi0tLSBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURv' \
        'Y2tlcmZpbGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tRG9ja2VyZmlsZQpAQCAtMSw0ICsxLDUg' \
        'QEAKIEZST00gcnVieToyLjUuNS1zbGltIGFzIGJ1aWxkZXIKK1JVTiB6eXBwZXIgcmVmIC0tZm9yY2UgJiYgenlwcGVyIGlu' \
        'c3RhbGwgLXkgLS1mb3JjZSBzb21ldGhpbmc9Mi4yLjEKIFJVTiBhcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3RhbGwg' \
        'LXkgLXEgXAogICB3Z2V0IFwKICAgZ2l0'
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
