# frozen_string_literal: true
RSpec.describe Gcs::Trivy do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
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

  before do
    allow(Gcs::Environment).to receive(:default_docker_image).and_return("alpine:latest")

    status = double(success?: true)

    allow(Gcs.shell).to receive(:execute).with(["trivy", "--version"]).and_return([version_data, nil, status])
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
    subject(:os_scan_image) { described_class.scan_os_packages(image_name, output_file_name) }

    it 'runs trivy binary with given severity levels' do
      allow(Gcs::Environment).to receive(:severity_level_name).and_return("LOW")
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
      allow(Gcs::Environment).to receive(:dependency_scan_disabled?).and_return(false)

      cmd = [
        "trivy image",
        "--list-all-pkgs",
        "--no-progress",
        "--offline-scan --skip-update",
        "--format json",
        "--output #{output_file_name}",
        image_name
      ]

      expect(Gcs.shell).to receive(:execute)
        .with(cmd, {
                'TRIVY_DEBUG' => '',
                'TRIVY_INSECURE' => 'false',
                'TRIVY_NON_SSL' => 'false',
                'TRIVY_PASSWORD' => nil,
                'TRIVY_USERNAME' => nil
              })

      os_scan_image
    end
  end

  describe 'scanning with trivy' do
    subject(:scan_image) { described_class.scan_image(image_name, output_file_name) }

    it 'runs trivy binary with given severity levels' do
      allow(Gcs::Environment).to receive(:severity_level_name).and_return("LOW")
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)

      cmd = [
        "trivy image",
        "--severity LOW,MEDIUM,HIGH,CRITICAL",
        "--vuln-type os",
        "--no-progress",
        "--offline-scan --skip-update",
        "--format template --template @#{described_class.template_file}",
        "--output #{output_file_name}",
        image_name
      ]

      expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                    "TRIVY_DEBUG" => "",
                                                    "TRIVY_INSECURE" => "false",
                                                    "TRIVY_NON_SSL" => "false",
                                                    "TRIVY_PASSWORD" => nil,
                                                    "TRIVY_USERNAME" => nil
                                                  })
      expect(Gcs.shell).to receive(:execute).with(["trivy", "--version"]).twice

      scan_image
    end

    it 'runs trivy binary without severity level' do
      allow(Gcs::Environment).to receive(:severity_level_name).and_return("UNKNOWN")
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)

      cmd = [
        "trivy image",
        "--vuln-type os",
        "--no-progress",
        "--offline-scan --skip-update",
        "--format template --template @#{described_class.template_file}",
        "--output #{output_file_name}",
        image_name
      ]

      expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                    "TRIVY_DEBUG" => "",
                                                    "TRIVY_INSECURE" => "false",
                                                    "TRIVY_NON_SSL" => "false",
                                                    "TRIVY_PASSWORD" => nil,
                                                    "TRIVY_USERNAME" => nil
                                                  })

      scan_image
    end

    context 'when language specific scan is enabled' do
      before do
        allow(Gcs::Environment).to receive(:severity_level_name).and_return("UNKNOWN")
        allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      it 'runs trivy binary without specifying type of vulnerability' do
        cmd = [
          "trivy image",
          "--no-progress",
          "--offline-scan --skip-update",
          "--format template --template @#{described_class.template_file}",
          "--output #{output_file_name}",
          image_name
        ]

        expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                      "TRIVY_DEBUG" => "",
                                                      "TRIVY_INSECURE" => "false",
                                                      "TRIVY_NON_SSL" => "false",
                                                      "TRIVY_PASSWORD" => nil,
                                                      "TRIVY_USERNAME" => nil
                                                    })
        expect(Gcs.shell).to receive(:execute).with(["trivy", "--version"]).twice

        scan_image
      end
    end

    context 'when ignoring unfixed vulnerabilities is enabled' do
      before do
        allow(Gcs::Environment).to receive(:severity_level_name).and_return("UNKNOWN")
        allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
        allow(Gcs::Environment).to receive(:ignore_unfixed_vulnerabilities?).and_return(true)
      end

      it 'runs trivy binary without specifying type of vulnerability' do
        cmd = [
          "trivy image",
          "--vuln-type os",
          "--ignore-unfixed",
          "--no-progress",
          "--offline-scan --skip-update",
          "--format template --template @#{described_class.template_file}",
          "--output #{output_file_name}",
          image_name
        ]

        expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                      "TRIVY_DEBUG" => "",
                                                      "TRIVY_INSECURE" => "false",
                                                      "TRIVY_NON_SSL" => "false",
                                                      "TRIVY_PASSWORD" => nil,
                                                      "TRIVY_USERNAME" => nil
                                                    })
        expect(Gcs.shell).to receive(:execute).with(["trivy", "--version"]).twice

        scan_image
      end
    end
  end
end
