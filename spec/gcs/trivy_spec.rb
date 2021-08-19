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
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(Gcs::Environment).to receive(:default_docker_image).and_return("alpine:latest")

    status = double(success?: true)

    allow(Gcs.shell).to receive(:execute).with(["trivy", "--version"]).and_return([version_data, nil, status])
  end

  describe '.db_updated_at' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:db_updated_at)).to eq('2021-05-19')
    end
  end

  describe '.scanner_version' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:scanner_version)).to eq('Version: 0.15.0')
    end
  end

  describe 'scanning with trivy' do
    subject(:scan_image) { described_class.scan_image(image_name, output_file_name) }

    it 'runs trivy binary with given severity levels' do
      allow(Gcs::Environment).to receive(:severity_level_name).and_return("LOW")
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)

      cmd = ["trivy i -s LOW,MEDIUM,HIGH,CRITICAL --skip-update --vuln-type os --no-progress --format template -t",
             "@#{described_class.template_file}",
             "-o",
             output_file_name,
             image_name]

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

      cmd = ["trivy i  --skip-update --vuln-type os --no-progress --format template -t",
             "@#{described_class.template_file}",
             "-o",
             output_file_name,
             image_name]

      expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                    "TRIVY_DEBUG" => "",
                                                    "TRIVY_INSECURE" => "false",
                                                    "TRIVY_NON_SSL" => "false",
                                                    "TRIVY_PASSWORD" => nil,
                                                    "TRIVY_USERNAME" => nil
                                                  })

      scan_image
    end
  end
end
