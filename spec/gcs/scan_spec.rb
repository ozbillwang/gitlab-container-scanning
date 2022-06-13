# frozen_string_literal: true

RSpec.describe Gcs::Scan do
  let(:plugin) { instance_double(Gcs::Plugin::ContainerScan) }
  let(:image_name) { 'ubuntu:latest' }
  let(:measured_time) { { end_time: "2022-01-05T13:29:08", start_time: "2022-01-05T13:29:08" } }

  before do
    allow(Gcs::Util).to receive(:measure_runtime).and_yield.and_return(measured_time)
  end

  describe '#scan_image' do
    subject(:scan_image) { described_class.new(plugin).scan_image(image_name) }

    context 'when plugin is disabled' do
      let(:skip_output) { 'skip output' }

      before do
        allow(plugin).to receive(:enabled?).and_return(false)
        allow(plugin).to receive(:skip).and_return(skip_output)
      end

      it 'calls skip and returns output' do
        expect(scan_image).to eq(skip_output)
      end
    end

    context 'when plugin is enabled' do
      let(:success) { true }

      before do
        allow(plugin).to receive(:enabled?).and_return(true)
        allow(plugin).to receive(:scan).with(image_name, 'tmp.json')
          .and_return([nil, nil, instance_double(Process::Status, success?: success)])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).with('tmp.json')
      end

      it 'runs the scan' do
        allow(plugin).to receive(:convert)
        expect(plugin).to receive(:scan).with(image_name, 'tmp.json')

        scan_image
      end

      context 'when scan was successful' do
        let(:success) { true }

        it 'runs convert stage' do
          expect(plugin).to receive(:convert).with(nil, measured_time.merge(image_name: image_name))

          expect(scan_image.success?).to eq(true)
        end
      end

      context 'when scan was not successful' do
        let(:success) { false }

        it 'handles errors' do
          expect(plugin).to receive(:handle_failure)
          expect(Gcs.logger).to receive(:error).twice

          expect(scan_image.success?).to eq(false)
        end
      end
    end
  end
end
