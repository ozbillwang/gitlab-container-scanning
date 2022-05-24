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

  describe '.setup' do
    let(:tmp_dir) { Dir.mktmpdir }

    let(:database_dest) { database_path("trivy.db") }
    let(:metadata_dest) { database_path("metadata.json") }

    let(:database_src) { File.readlink(database_path("trivy.db")) }
    let(:metadata_src) { File.readlink(database_path("metadata.json")) }

    def database_path(*segments)
      File.join(described_class::DATABASE_PATH, *segments)
    end

    before do
      stub_const('Gcs::Trivy::DATABASE_PATH', tmp_dir)

      %w[ce ee].each do |segment|
        FileUtils.mkdir_p(database_path(segment))
        FileUtils.touch(database_path(segment, "trivy.db"))
        FileUtils.touch(database_path(segment, "metadata.json"))
      end

      described_class.setup
    end

    around do |example|
      with_modified_environment 'GITLAB_FEATURES' => features do
        example.run
      end
    end

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    context 'when EE' do
      let(:features) { 'container_scanning' }

      it 'symlinks the EE database' do
        expect(database_src).to eq(database_path("ee", "trivy.db"))
      end

      it 'symlinks EE metadata' do
        expect(metadata_src).to eq(database_path("ee", "metadata.json"))
      end

      context 'when already setup' do
        it 'does not symlink' do
          expect { described_class.setup }.not_to raise_error
        end
      end
    end

    context 'when CE' do
      let(:features) { '' }

      it 'symlinks the CE database' do
        expect(database_src).to eq(database_path("ce", "trivy.db"))
      end

      it 'symlinks CE metadata' do
        expect(metadata_src).to eq(database_path("ce", "metadata.json"))
      end

      context 'when already setup' do
        it 'does not symlink' do
          expect { described_class.setup }.not_to raise_error
        end
      end
    end
  end

  describe '.db_updated_at' do
    before do
      allow(described_class).to receive(:setup)
    end

    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:db_updated_at)).to eq('2021-05-19T12:06:02+00:00')
    end
  end

  describe '.scanner_version' do
    before do
      allow(described_class).to receive(:setup)
    end

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
      allow(described_class).to receive(:setup)
      allow(Gcs::Environment).to receive(:severity_level_name).and_return("LOW")
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
      allow(Gcs::Environment).to receive(:dependency_scan_disabled?).and_return(false)

      cmd = [
        "trivy image",
        "--list-all-pkgs",
        "--no-progress",
        "--offline-scan --skip-update --security-checks vuln",
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
      allow(described_class).to receive(:setup)
      allow(Gcs::Environment).to receive(:severity_level_name).and_return("LOW")
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)

      cmd = [
        "trivy image",
        "--severity LOW,MEDIUM,HIGH,CRITICAL",
        "--vuln-type os",
        "--no-progress",
        "--offline-scan --skip-update --security-checks vuln",
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
      allow(described_class).to receive(:setup)
      allow(Gcs::Environment).to receive(:severity_level_name).and_return("UNKNOWN")
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)

      cmd = [
        "trivy image",
        "--vuln-type os",
        "--no-progress",
        "--offline-scan --skip-update --security-checks vuln",
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
        allow(described_class).to receive(:setup)
        allow(Gcs::Environment).to receive(:severity_level_name).and_return("UNKNOWN")
        allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      it 'runs trivy binary without specifying type of vulnerability' do
        cmd = [
          "trivy image",
          "--no-progress",
          "--offline-scan --skip-update --security-checks vuln",
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
        allow(described_class).to receive(:setup)
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
          "--offline-scan --skip-update --security-checks vuln",
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
