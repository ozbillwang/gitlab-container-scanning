RSpec.describe Gcs::Remediation do
  let(:multi_build_docker_file_path) { fixture_file('docker/remediation-multibuild-Dockerfile') }
  let(:docker_file_path) { fixture_file('docker/remediation-Dockerfile') }

  after :each do
    `git checkout #{multi_build_docker_file_path.to_path}` unless ENV['CI']
    `git checkout #{docker_file_path.to_path}` unless ENV['CI']
  end

#   describe 'for multi build docker file' do
#     let(:remediation) do
#       described_class.new(
#         {
#           'package_name' => 'curl',
#           'package_version' => '2.0.0',
#           'fixed_version' => '2.2.1',
#           'operating_system' => 'centos',
#           'summary' => 'Upgrade curl to 2.2.1'
#         },
#         multi_build_docker_file_path
#       )
#     end

#     it 'remediatiates multi build docker file' do
#       remediation.add_fix('123', '456')
#       expected_diff = <<~ST
#       ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9u
#       LURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVzL2RvY2tlci9yZW1lZGlhdGlv
#       bi1Eb2NrZXJmaWxlCmluZGV4IDZmMzIzNzcuLjE4MzcxYWIgMTAwNjQ0Ci0t
#       LSBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZp
#       bGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tRG9j
#       a2VyZmlsZQpAQCAtNiw2ICs2LDcgQEAgQ09QWSAuIHByb2plY3QKIFdPUktE
#       SVIgL3Byb2plY3QKIAogRlJPTSBjZW50b3M6Y2VudG9zOAoreXVtIC15IGNo
#       ZWNrLXVwZGF0ZSB8fCB7IHJjPSQ/OyBbICRyYyAtbmVxIDEwMCBdICYmIGV4
#       aXQgJHJjOyB5dW0gdXBkYXRlIC15IGN1cmw7IH0gJiYgeXVtIGNsZWFuIGFs
#       bAogRU5WIFBBVEg9Ii9vcHQvZ2l0bGFiOiR7UEFUSH0iCiBDT1BZIC0tZnJv
#       bT1idWlsZGVyIC9wcm9qZWN0ICAvb3B0L2dpdGxhYi8KIFJVTiB5dW0gaW5z
#       dGFsbCAteSBjYS1jZXJ0aWZpY2F0ZXMgZ2l0LWNvcmUgeHogcnVieQo=
#       ST
#       expect(remediation.to_hash).to include(
#         fixes: [{ 'cve' => '123', 'id' => '456' }],
#         summary: 'Upgrade curl to 2.2.1',
#         diff: expected_diff
#       )
#     end
#   end

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


      expected_diff = <<~ST
      ZGlmZiAtLWdpdCBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9u
      LURvY2tlcmZpbGUgYi9zcGVjL2ZpeHR1cmVzL2RvY2tlci9yZW1lZGlhdGlv
      bi1Eb2NrZXJmaWxlCmluZGV4IDZmMzIzNzcuLmM5ZmNmZmMgMTAwNjQ0Ci0t
      LSBhL3NwZWMvZml4dHVyZXMvZG9ja2VyL3JlbWVkaWF0aW9uLURvY2tlcmZp
      bGUKKysrIGIvc3BlYy9maXh0dXJlcy9kb2NrZXIvcmVtZWRpYXRpb24tRG9j
      a2VyZmlsZQpAQCAtNiw2ICs2LDcgQEAgQ09QWSAuIHByb2plY3QKIFdPUktE
      SVIgL3Byb2plY3QKIAogRlJPTSBjZW50b3M6Y2VudG9zOAorYXB0LWdldCB1
      cGRhdGUgJiYgYXB0LWdldCB1cGdyYWRlIC15IGFwdCAmJiBybSAtcmYgL3Zh
      ci9saWIvYXB0L2xpc3RzLyoKIEVOViBQQVRIPSIvb3B0L2dpdGxhYjoke1BB
      VEh9IgogQ09QWSAtLWZyb209YnVpbGRlciAvcHJvamVjdCAgL29wdC9naXRs
      YWIvCiBSVU4geXVtIGluc3RhbGwgLXkgY2EtY2VydGlmaWNhdGVzIGdpdC1j
      b3JlIHh6IHJ1YnkK
      ST
      expect(remediation.to_hash).to include(
        fixes: [{ 'cve' => '123', 'id' => '456' }],
        summary: 'Upgrade apt to 2.2.1',
        diff: expected_diff
      )
    end
  end
end
