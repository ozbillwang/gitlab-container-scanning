# frozen_string_literal: true

RSpec.describe Gcs::Plugin::SbomScan do
  describe '#convert' do
    let(:json_string) { '{"foo":"bar"}' }
    let(:full_path) { Pathname.new('gitlab/my_project') }

    subject(:convert) { described_class.new.convert(json_string, nil) }

    specify do
      allow(Gcs::Environment).to receive_message_chain(:project_dir, :join).and_return(full_path)

      expect(Gcs).to receive_message_chain(:logger, :debug).with("writing results to sbom #{full_path}")
      expect(FileUtils).to receive(:mkdir_p).with(full_path.dirname)
      expect(IO).to receive(:write).with(full_path, json_string)
      convert
    end
  end

  describe '#enabled?' do
    it 'always returns true' do
      expect(described_class.new.enabled?).to eq(true)
    end
  end
end
