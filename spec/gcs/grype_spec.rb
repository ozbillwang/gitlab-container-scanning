# frozen_string_literal: true
RSpec.describe Gcs::Grype do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
  let(:template_file) { File.join(Gcs.lib, 'gitlab.grype.tpl') }
  let(:version_data) do
    <<~HEREDOC
      Application:          grype
      Version:              0.12.1
      BuildDate:            2021-05-25T18:17:35Z
      GitCommit:            7bdfffb43dcf75bfd4c8a3eec8f8ee0e2b97ab01
      GitTreeState:         clean
      Platform:             linux/amd64
      GoVersion:            go1.16.4
      Compiler:             gc
      Supported DB Schema:  2
    HEREDOC
  end

  let(:db_status) do
    <<~HEREDOC
      Location:  /home/gitlab/.cache/grype/db/2
      Built:     2021-06-15 08:25:06 +0000 UTC
      Schema:    2
      Checksum:  sha256:14bb5d045ce7a00d54b4fd72cfbecffba475ae6b65ea68da9153563ac1677154
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
        "with gcs #{Gcs::VERSION} and Grype Version: 0.12.1, " \
        "advisories updated at 2021-06-15\n"
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
        "with gcs #{Gcs::VERSION} and Grype Version: 0.12.1, " \
        "advisories updated at 2021-06-15\n"
      )

      subject
    end
  end
end
