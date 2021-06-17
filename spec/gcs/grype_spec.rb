# frozen_string_literal: true
RSpec.describe Gcs::Grype do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
  let(:template_file) { File.join(Gcs.lib, 'gitlab.grype.tpl') }
  let(:version_data) do
    <<~HEREDOC
      Application:          grype
      Version:              0.13.0
      BuildDate:            2021-06-02T01:57:12Z
      GitCommit:            3d21b8397d65770d292184b09a4f676bce6f3ec8
      GitTreeState:         clean
      Platform:             linux/amd64
      GoVersion:            go1.16.4
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
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(Gcs::Environment).to receive(:default_docker_image).and_return("alpine:latest")

    status = double(success?: true)

    allow(Gcs.shell).to receive(:execute).with(%w[grype version]).and_return([version_data, nil, status])
    allow(Gcs.shell).to receive(:execute).with("grype db status").and_return([db_status, nil, status])
  end

  subject { described_class.scan_image(image_name, output_file_name) }

  describe 'scanning with grype' do
    it 'runs grype binary with empty docker credentials' do
      allow(Gcs::Environment).to receive(:docker_registry_credentials).and_return(nil)
      allow(Gcs::Environment).to receive(:docker_registry_security_config).and_return({ docker_insecure: false })

      cmd = ["grype -v registry:#{image_name} -o template -t #{template_file} > #{output_file_name}"]

      expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                    "GRYPE_CHECK_FOR_APP_UPDATE" => "false",
                                                    "GRYPE_DB_AUTO_UPDATE" => "false",
                                                    "GRYPE_REGISTRY_AUTH_PASSWORD" => nil,
                                                    "GRYPE_REGISTRY_AUTH_USERNAME" => nil,
                                                    "GRYPE_REGISTRY_INSECURE_SKIP_TLS_VERIFY" => "false"
                                                  })
      expect(Gcs.shell).to receive(:execute).with(%w[grype version]).once
      expect(Gcs.shell).to receive(:execute).with("grype db status").once
      expect(Gcs.logger).to receive(:info).with(
        "Scanning container from registry alpine:latest for vulnerabilities " \
        "with severity level UNKNOWN or higher, " \
        "with gcs #{Gcs::VERSION} and Grype Version: 0.13.0, " \
        "advisories updated at 2021-06-16\n"
      )

      subject
    end

    it 'runs grype binary with given severity levels' do
      allow(Gcs::Environment).to receive(:docker_registry_credentials)
                                   .and_return({ 'username' => 'username', 'password' => 'password' })
      allow(Gcs::Environment).to receive(:docker_registry_security_config).and_return({ docker_insecure: true })
      allow(Gcs::Environment).to receive(:log_level).and_return("debug")

      cmd = ["grype -vv registry:#{image_name} -o template -t #{template_file} > #{output_file_name}"]

      expect(Gcs.shell).to receive(:execute).with(cmd, {
                                                    "GRYPE_CHECK_FOR_APP_UPDATE" => "false",
                                                    "GRYPE_DB_AUTO_UPDATE" => "false",
                                                    "GRYPE_REGISTRY_AUTH_PASSWORD" => "password",
                                                    "GRYPE_REGISTRY_AUTH_USERNAME" => "username",
                                                    "GRYPE_REGISTRY_INSECURE_SKIP_TLS_VERIFY" => "true"
                                                  })
      expect(Gcs.shell).to receive(:execute).with(%w[grype version]).once
      expect(Gcs.shell).to receive(:execute).with("grype db status").once
      expect(Gcs.logger).to receive(:info).with(
        "Scanning container from registry alpine:latest for vulnerabilities " \
        "with severity level UNKNOWN or higher, " \
        "with gcs #{Gcs::VERSION} and Grype Version: 0.13.0, " \
        "advisories updated at 2021-06-16\n"
      )

      subject
    end
  end
end
