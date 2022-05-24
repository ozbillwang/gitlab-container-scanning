# frozen_string_literal: true
RSpec.describe Gcs::Trivy do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
  let(:features) { '' }
  let(:expected_cache_dir) { "/home/gitlab/.cache/trivy/db/ce" }
  let(:severity_threshold) { "UNKNOWN" }

  let(:version_data) do
    <<~HEREDOC
      Version: 0.15.0
      Vulnerability DB:
        Type: Light
        Version: 1
        UpdatedAt: 2021-05-19 12:06:02.55303056 +0000 UTC
        NextUpdate: 2021-05-20 00:06:02.55303016 +0000 UTC
        DownloadedAt: 2021-05-19 13:51:07.44954 +0000 UTC
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

    status = double(success?: true)

    allow(Gcs.shell).to receive(:execute).with(["trivy", "--version"]).and_return([version_data, nil, status])
  end

  RSpec.shared_examples 'scan image command' do
    it 'calls #execute with expected command and environment' do
      expect(Gcs.shell).to receive(:execute).with(expected_command, expected_environment)
      expect(Gcs.shell).to receive(:execute).with(["trivy", "--version"]).twice

      scan_image
    end
  end

  describe '.db_updated_at' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:db_updated_at)).to eq('2021-05-19T12:06:02+00:00')
    end
  end

  describe '.scanner_version' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:scanner_version)).to eq('Version: 0.15.0')
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
        "trivy image",
        "--list-all-pkgs",
        "--no-progress",
        "--offline-scan --skip-update --security-checks vuln",
        "--format json",
        "--output #{output_file_name}",
        image_name
      ]
    end

    context 'when given severity levels' do
      let(:severity_threshold) { "HIGH" }
      # Should behave the same as default because OS package list does not have severities

      before do
        allow(Gcs::Environment).to receive(:dependency_scan_disabled?).and_return(false)
      end

      it_behaves_like 'scan image command'
    end

    context 'when EE' do
      let(:features) { 'container_scanning' }
      let(:expected_cache_dir) { "/home/gitlab/.cache/trivy/db/ee" }

      it_behaves_like 'scan image command'
    end
  end

  describe 'scanning with trivy' do
    subject(:scan_image) { described_class.scan_image(image_name, output_file_name) }

    let(:expected_command) do
      [
        "trivy image",
        "--vuln-type os",
        "--no-progress",
        "--offline-scan --skip-update --security-checks vuln",
        "--format template --template @#{described_class.template_file}",
        "--output #{output_file_name}",
        image_name
      ]
    end

    context 'when given severity levels' do
      let(:severity_threshold) { "HIGH" }

      let(:expected_command) do
        [
          "trivy image",
          "--severity HIGH,CRITICAL",
          "--vuln-type os",
          "--no-progress",
          "--offline-scan --skip-update --security-checks vuln",
          "--format template --template @#{described_class.template_file}",
          "--output #{output_file_name}",
          image_name
        ]
      end

      it_behaves_like 'scan image command'
    end

    context 'when language specific scan is enabled' do
      let(:expected_command) do
        [
          "trivy image",
          "--no-progress",
          "--offline-scan --skip-update --security-checks vuln",
          "--format template --template @#{described_class.template_file}",
          "--output #{output_file_name}",
          image_name
        ]
      end

      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      it_behaves_like 'scan image command'
    end

    context 'when ignoring unfixed vulnerabilities is enabled' do
      let(:expected_command) do
        [
          "trivy image",
          "--vuln-type os",
          "--ignore-unfixed",
          "--no-progress",
          "--offline-scan --skip-update --security-checks vuln",
          "--format template --template @#{described_class.template_file}",
          "--output #{output_file_name}",
          image_name
        ]
      end

      before do
        allow(Gcs::Environment).to receive(:ignore_unfixed_vulnerabilities?).and_return(true)
      end

      it_behaves_like 'scan image command'
    end

    context 'when EE' do
      let(:features) { 'container_scanning' }
      let(:expected_cache_dir) { "/home/gitlab/.cache/trivy/db/ee" }

      it_behaves_like 'scan image command'
    end
  end
end
