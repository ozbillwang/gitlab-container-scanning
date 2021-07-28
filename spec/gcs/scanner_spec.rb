# frozen_string_literal: true
RSpec.describe Gcs::Scanner do
  before do
    my_scanner = Class.new(described_class)
    stub_const('MyScanner', my_scanner)
  end

  describe '.template_file' do
    it 'returns a path in template/ based on the class name' do
      expect(MyScanner.template_file).to end_with 'lib/template/myscanner.tpl'
    end
  end

  describe '.scan_image' do
    let(:log_message) { 'Scanning blah blah blah' }
    let(:image_name) { 'registry.example.com/image' }
    let(:output_file_name) { 'path/to/gl-report.json' }
    let(:command) { 'scanner -a -b' }
    let(:environment) { { 'ZOOT' => 'pants' } }

    before do
      allow(described_class).to receive(:scan_command).and_return(command)
      allow(described_class).to receive(:log_message).and_return(log_message)
      allow(described_class).to receive(:environment).and_return(environment)
    end

    subject { MyScanner.scan_image(image_name, output_file_name) }

    it 'logs an execution message before running scan' do
      expect(Gcs.logger).to receive(:info).with(log_message)
      expect(Gcs.shell).to receive(:execute)

      subject
    end

    it 'executes the scan_command with correct arguments and environment' do
      expect(Gcs.shell).to receive(:execute).with(command, environment)

      subject
    end
  end
end
