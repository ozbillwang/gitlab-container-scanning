# frozen_string_literal: true

RSpec.describe Gcs::Plugin::SbomScan do
  describe '#convert' do
    let(:json_string) { '{"foo":"bar"}' }

    subject(:convert) { described_class.new.convert(json_string, nil) }

    specify do
      expect(Gcs::Util).to receive(:write_file).with(Gcs::DEFAULT_SBOM_REPORT_NAME, json_string, Pathname.pwd, nil)

      convert
    end
  end

  describe '#enabled?' do
    it 'always returns true' do
      expect(described_class.new.enabled?).to eq(true)
    end
  end
end
