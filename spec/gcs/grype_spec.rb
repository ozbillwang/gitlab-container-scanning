# frozen_string_literal: true
RSpec.describe Gcs::Grype do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
  let(:version_data) do
    <<~HEREDOC
      Application:          grype
      Version:              0.23.0
      BuildDate:            2021-08-18T15:41:58Z
      GitCommit:            01a77d5c451455e6125f26178db6fe2da2b7675d
      GitTreeState:         clean
      Platform:             linux/amd64
      GoVersion:            go1.16.7
      Compiler:             gc
      Supported DB Schema:  3
    HEREDOC
  end

  let(:db_status) do
    <<~HEREDOC
      Location:  /home/gitlab/.cache/grype/db/3
      Built:     2021-06-16 08:33:35 +0000 UTC
      Schema:    3
      Checksum:  sha256:759221b59f22d7d426ba092d2bd28b4b074cf7b5b783f7e0e3ddc1b1bd30178c
      Status:    valid
    HEREDOC
  end

  before do
    allow(Gcs::Environment).to receive(:default_docker_image).and_return("alpine:latest")

    status = double(success?: true)

    allow(Gcs.shell).to receive(:execute).with(%w[grype version]).and_return([version_data, nil, status])
    allow(Gcs.shell).to receive(:execute).with("grype db status").and_return([db_status, nil, status])
  end

  describe '.db_updated_at' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:db_updated_at)).to eq('2021-06-16T08:33:35+00:00')
    end
  end

  describe '.scanner_version' do
    it 'returns the value extracted from the scanner output' do
      expect(described_class.send(:scanner_version)).to eq('Version: 0.23.0')
    end
  end

  describe '.scan_os_packages_supported?' do
    subject { described_class.scan_os_packages_supported? }

    it { is_expected.to be false }
  end

  describe 'scanning with grype' do
    subject(:scan_image) { described_class.scan_image(image_name, output_file_name) }

    it 'runs grype binary with empty docker credentials' do
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
      allow(Gcs::Environment).to receive(:docker_registry_security_config)
                                   .and_return({ docker_insecure: false, registry_insecure: false })

      cmd = ["grype -v registry:#{image_name} -o template -t #{described_class.template_file} > #{output_file_name}"]

      expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                    "GRYPE_CHECK_FOR_APP_UPDATE" => "false",
                                                    "GRYPE_DB_AUTO_UPDATE" => "false",
                                                    "GRYPE_REGISTRY_AUTH_PASSWORD" => nil,
                                                    "GRYPE_REGISTRY_AUTH_USERNAME" => nil,
                                                    "GRYPE_REGISTRY_INSECURE_SKIP_TLS_VERIFY" => "false",
                                                    "GRYPE_REGISTRY_INSECURE_USE_HTTP" => "false"
                                                  })
      expect(Gcs.shell).to receive(:execute).with(%w[grype version]).once
      expect(Gcs.shell).to receive(:execute).with("grype db status").once

      scan_image
    end

    it 'runs grype binary with given severity levels' do
      allow(Gcs::Environment).to receive(:docker_registry_credentials)
                                   .and_return({ 'username' => 'username', 'password' => 'password' })
      allow(Gcs::Environment).to receive(:docker_registry_security_config)
                                   .and_return({ docker_insecure: true, registry_insecure: true })
      allow(Gcs::Environment).to receive(:log_level).and_return("debug")

      cmd = ["grype -vv registry:#{image_name} -o template -t #{described_class.template_file} > #{output_file_name}"]

      expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                    "GRYPE_CHECK_FOR_APP_UPDATE" => "false",
                                                    "GRYPE_DB_AUTO_UPDATE" => "false",
                                                    "GRYPE_REGISTRY_AUTH_PASSWORD" => "password",
                                                    "GRYPE_REGISTRY_AUTH_USERNAME" => "username",
                                                    "GRYPE_REGISTRY_INSECURE_SKIP_TLS_VERIFY" => "true",
                                                    "GRYPE_REGISTRY_INSECURE_USE_HTTP" => "true"
                                                  })
      expect(Gcs.shell).to receive(:execute).with(%w[grype version]).once
      expect(Gcs.shell).to receive(:execute).with("grype db status").once

      scan_image
    end
  end
end
