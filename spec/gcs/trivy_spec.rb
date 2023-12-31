# frozen_string_literal: true
RSpec.describe Gcs::Trivy do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
  let(:features) { '' }
  let(:expected_cache_dir) { "/home/gitlab/.cache/trivy/ce" }
  let(:severity_threshold) { "UNKNOWN" }
  let(:version_status) { instance_double(Process::Status, success?: true) }

  let(:version_data) do
    <<~HEREDOC
      Version: 0.28.0
      Vulnerability DB:
        Version: 2
        UpdatedAt: 2022-05-24 12:07:24.230321126 +0000 UTC
        NextUpdate: 2022-05-24 18:07:24.230320726 +0000 UTC
        DownloadedAt: 2022-05-24 17:47:39.475919046 +0000 UTC
    HEREDOC
  end

  let(:expected_environment) do
    {
      'TRIVY_CACHE_DIR' => expected_cache_dir,
      'TRIVY_DEBUG' => '',
      'TRIVY_INSECURE' => 'false',
      'TRIVY_NON_SSL' => 'false',
      'TRIVY_PASSWORD' => nil,
      'TRIVY_USERNAME' => nil
    }
  end

  around do |example|
    with_modified_environment 'GITLAB_FEATURES' => features do
      example.run
    end
  end

  before do
    allow(Gcs::Environment).to receive(:default_docker_image).and_return("alpine:latest")
    allow(Gcs::Environment).to receive(:severity_level_name).and_return(severity_threshold)
    allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
    allow(Gcs.shell).to receive(:execute).with(["trivy", "--version"], expected_environment)
      .and_return([version_data, nil, version_status])
  end

  RSpec.shared_examples 'expected command' do
    it 'calls #execute with expected command and environment' do
      expect(Gcs.shell).to receive(:execute).with(expected_command, expected_environment)
      expect(Gcs.shell).to receive(:execute).with(["trivy", "--version"], expected_environment).twice
      scan_image
    end
  end

  shared_context 'with scan image command' do
    context 'when CE' do
      include_context 'expected command'
    end

    context 'when EE' do
      let(:features) { 'container_scanning' }
      let(:expected_cache_dir) { "/home/gitlab/.cache/trivy/ee" }

      include_context 'expected command'
    end
  end

  describe '.db_updated_at' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:db_updated_at)).to eq('2022-05-24T12:07:24+00:00')
    end
  end

  describe '.version_info' do
    subject(:version_info) { described_class.send(:version_info) }

    it 'calls trivy --version with expected environment' do
      expect(Gcs.shell).to receive(:execute).with(["trivy", "--version"], expected_environment)
      version_info
    end

    it 'returns correct data' do
      expect(version_info).to eq(
        {
          binary_version: "Version: 0.28.0",
          db_updated_at: "2022-05-24T12:07:24+00:00"
        }
      )
    end

    context 'when version command fails' do
      let(:version_status) { instance_double(Process::Status, success?: false) }

      it 'returns UNKNOWN_VERSIONS' do
        expect(version_info).to eq(described_class::UNKNOWN_VERSIONS)
      end
    end

    context 'when version output is not parseable' do
      let(:version_data) { "??????" }

      it 'returns UNKNOWN_VERSIONS' do
        expect(version_info).to eq(described_class::UNKNOWN_VERSIONS)
      end
    end
  end

  describe '.scanner_version' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:scanner_version)).to eq('Version: 0.28.0')
    end
  end

  describe '.scan_os_packages_supported?' do
    subject { described_class.scan_os_packages_supported? }

    it { is_expected.to be true }
  end

  describe '.scan_os_packages' do
    subject(:scan_image) { described_class.scan_os_packages(image_name, output_file_name) }

    let(:expected_command) do
      [
        "echo 1 trivy image",
        "-s HIGH,CRITICAL",
        image_name
      ]
    end

    context 'when given severity levels' do
      let(:severity_threshold) { "HIGH" }
      # Should behave the same as default because OS package list does not have severities

      before do
        allow(Gcs::Environment).to receive(:dependency_scan_disabled?).and_return(false)
      end

      it_behaves_like 'with scan image command'
    end
  end

  describe '.scan_sbom_supported?' do
    subject { described_class.scan_sbom_supported? }

    it { is_expected.to be true }
  end

  describe '.scan_sbom' do
    subject(:scan_image) { described_class.scan_sbom(image_name, output_file_name) }

    let(:expected_command) do
      [
        "echo 2 trivy image",
        "-s HIGH,CRITICAL",
        image_name
      ]
    end

    it_behaves_like 'with scan image command'
  end

  describe 'scanning with trivy' do
    subject(:scan_image) { described_class.scan_image(image_name, output_file_name) }

    let(:expected_command) do
      [
        "echo 3 trivy image",
        "-s HIGH,CRITICAL",
        image_name
      ]
    end

    context 'when given severity levels' do
      let(:severity_threshold) { "HIGH" }

      let(:expected_command) do
        [
          "echo 4 trivy image",
          "-s HIGH,CRITICAL",
          image_name
        ]
      end

      it_behaves_like 'with scan image command'
    end

    context 'when language specific scan is enabled' do
      let(:expected_command) do
        [
          "echo 5 trivy image",
          "-s HIGH,CRITICAL",
          image_name
        ]
      end

      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      it_behaves_like 'with scan image command'
    end

    context 'when ignoring unfixed vulnerabilities is enabled' do
      let(:expected_command) do
        [
          "echo 6 trivy image",
          "-s HIGH,CRITICAL",
          image_name
        ]
      end

      before do
        allow(Gcs::Environment).to receive(:ignore_unfixed_vulnerabilities?).and_return(true)
      end

      it_behaves_like 'with scan image command'
    end
  end
end
