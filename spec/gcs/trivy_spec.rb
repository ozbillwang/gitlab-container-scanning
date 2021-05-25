# frozen_string_literal: true
RSpec.describe Gcs::Trivy do
  let(:image_name) { 'alpine:latest' }
  let(:output_file_name) { 'gl-report.json' }
  let(:trivy_template_file) { "@#{File.join(Gcs.lib, 'gitlab.tpl')}" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(Gcs.shell).to receive(:execute).and_return('')
  end

  subject { described_class.scan_image(image_name, output_file_name) }

  describe 'scanning with trivy' do
    it 'runs trivy binary with given severity levels' do
      allow(Gcs::Environment).to receive(:severity_level).and_return(1)
      allow(described_class).to receive(:trivy_version).and_return("V1.0.0")

      cmd = ["trivy i -s LOW,MEDIUM,HIGH,CRITICAL --skip-update --vuln-type os --no-progress --format template -t",
             trivy_template_file,
             "-o",
             output_file_name,
             image_name]

      expect(Gcs.shell).to receive(:execute).with(cmd)

      subject
    end

    it 'runs trivy binary without severity level' do
      allow(Gcs::Environment).to receive(:severity_level).and_return(0)
      allow(described_class).to receive(:trivy_version).and_return("V1.0.0")

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
