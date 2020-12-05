# frozen_string_literal: true

RSpec.describe Gcs::Cli do
  let(:commit_sha) { '85cbadce93fec0d78225fc00897221d8a74cb1f9' }
  let(:ci_registry_image) { 'registry.gitlab.com/defen/trivy-test' }
  let(:ci_commit_ref_slug) { 'master ' }
  let(:tag) { latest }

  it 'exists when scan fails' do
    arguments = ['scan', 'ubuntu:latest']
    allow(Gcs::Trivy).to receive(:scan_image).with('ubuntu:latest').and_return([nil, nil, double(success?: false)])

    execution = -> { Gcs::Cli.start(arguments) }
    expect(Gcs::Trivy).to receive(:scan_image).with('ubuntu:latest')
    expect(execution).to terminate.with_code(1)
  end
end