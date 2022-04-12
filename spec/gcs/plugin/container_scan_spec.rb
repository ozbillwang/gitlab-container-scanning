# frozen_string_literal: true

RSpec.describe Gcs::Plugin::ContainerScan do
  describe '#convert' do
    subject(:convert) { described_class.new.convert(nil, nil) }

    before do
      allow(Gcs::Converter).to receive_message_chain(:new, :convert).and_return({})
    end

    context 'with invalid allow list file' do
      before do
        allow(File).to receive(:read).and_return('"') # smallest broken yaml
      end

      specify do
        expect(Gcs::Util).to receive(:write_table).with({}, nil)
        expect(Gcs::Util).to receive(:write_file).with(Gcs::DEFAULT_REPORT_NAME, {}, Pathname.pwd, nil)

        convert
      end
    end
  end

  describe '#enabled?' do
    it 'always returns true' do
      expect(described_class.new.enabled?).to eq(true)
    end
  end
end
