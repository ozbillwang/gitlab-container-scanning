# frozen_string_literal: true
RSpec.describe Gcs::Trivy do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
  let(:trivy_template_file) { "@#{File.join(Gcs.lib, 'gitlab.tpl')}" }
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

  subject { described_class.scan_image(image_name, output_file_name) }

  describe 'scanning with trivy' do
    it 'runs trivy binary with given severity levels' do
      allow(Gcs::Environment).to receive(:severity_level).and_return(1)

      cmd = ["trivy i -s LOW,MEDIUM,HIGH,CRITICAL --skip-update --vuln-type os --no-progress --format template -t",
             trivy_template_file,
             "-o",
             output_file_name,
             image_name]

      expect(Gcs.shell).to receive(:execute).with(cmd)
      expect(Gcs.logger).to receive(:info).with(
        "Scanning container from registry alpine:latest for vulnerabilities with " \
        "severity level UNKNOWN or higher, " \
        "with gcs #{Gcs::VERSION} and Trivy Version: 0.15.0, " \
        "advisories updated at 2021-05-19\n"
      )

      subject
    end

    it 'runs trivy binary without severity level' do
      allow(Gcs::Environment).to receive(:severity_level).and_return(0)

      cmd = ["trivy i  --skip-update --vuln-type os --no-progress --format template -t",
             trivy_template_file,
             "-o",
             output_file_name,
             image_name]

      expect(Gcs.shell).to receive(:execute).with(cmd)

      subject
    end
  end
end
