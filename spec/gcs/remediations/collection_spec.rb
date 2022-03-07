# frozen_string_literal: true

RSpec.describe Gcs::Remediations::Collection do
  let(:remediation_collection) { described_class.new }

  modify_environment 'CI_DEFAULT_BRANCH' => 'main',
                     'CI_REGISTRY_IMAGE' => 'registry.example.com/group/project',
                     'CI_APPLICATION_TAG' => 'latest'

  describe '#disabled?' do
    context 'when docker_file exists' do
      let(:docker_file) { fixture_file('docker/remediation-Dockerfile') }

      it 'returns false' do
        expect(described_class.new(docker_file).disabled?).to be false
      end
    end

    context 'when docker_file is missing' do
      let(:docker_file) { Pathname.new('/path/to/some/non-existing/file') }

      it 'returns true' do
        expect(described_class.new(docker_file).disabled?).to be true
      end
    end
  end

  describe '#create_remediation' do
    let(:vulnerability) { JSON.parse(fixture_file_content('report.json'))['vulnerabilities'][0] }
    let(:converted_vuln) { Gcs::Vulnerability.new(vulnerability) }

    subject(:create_remediation) { remediation_collection.create_remediation(converted_vuln, vulnerability) }

    it 'checks whether remediations are disabled' do
      expect(remediation_collection).to receive(:disabled?).once
      create_remediation
    end

    context 'when OS is unsupported' do
      let(:vulnerability) { JSON.parse(fixture_file_content('trivy-unsupported-os.json'))['vulnerabilities'][0] }

      before do
        create_remediation
      end

      it 'skips remediation' do
        expect(remediation_collection.to_hash).to be_empty
      end

      it 'adds OS to unsupported list' do
        expect(remediation_collection.unsupported_operating_systems).to include("unsupported-os 1.12")
      end
    end

    context 'when OS is supported' do
      let(:docker_file) { fixture_file('docker/remediation-Dockerfile') }
      let(:remediation_collection) { described_class.new(docker_file) }

      before do
        create_remediation
      end

      it 'adds remediation' do
        expect(remediation_collection.to_hash[0]).to include(summary: 'Upgrade apt to 1.4.9')
      end
    end
  end
end
