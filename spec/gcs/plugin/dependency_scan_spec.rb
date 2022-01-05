# frozen_string_literal: true

RSpec.describe Gcs::Plugin::DependencyScan do
  describe '#convert' do
    subject(:convert) { described_class.new.convert(nil, nil) }

    before do
      allow(Gcs::DependencyListConverter).to receive_message_chain(:new, :convert).and_return({})
      allow(File).to receive(:read).with(%r{lib/template/dependencies-(trivy|grype)\.json})
    end

    specify do
      expect(Gcs::Util).to receive(:write_file).with(Gcs::DEFAULT_DEPENDENCY_REPORT_NAME, {}, Pathname.pwd, nil)

      convert
    end
  end

  describe '#enabled?' do
    subject(:enabled) { described_class.new.enabled? }

    it 'is enabled by default' do
      expect(enabled).to eq(true)
    end

    context 'when disabled via environment variable' do
      before do
        allow(ENV).to receive(:fetch).with('CS_DISABLE_DEPENDENCY_LIST', 'false').and_return('true')
      end

      it 'returns false' do
        expect(enabled).to eq(false)
      end
    end

    context 'when scanner supports dependency scanning' do
      before do
        allow(Gcs::Environment).to receive_message_chain(:scanner, :scan_os_packages_supported?)
          .and_return(true)
      end

      it 'returns false' do
        expect(enabled).to eq(true)
      end
    end

    context 'when scanner does not support dependency scanning' do
      before do
        allow(Gcs::Environment).to receive_message_chain(:scanner, :scan_os_packages_supported?)
          .and_return(false)
      end

      it 'returns false' do
        expect(enabled).to eq(false)
      end
    end
  end

  describe '#skip' do
    subject(:skip) { described_class.new.skip }

    before do
      allow(Gcs::DependencyListConverter).to receive_message_chain(:new, :convert).and_return({})
      allow(File).to receive(:read).with(%r{lib/template/dependencies-(trivy|grype)\.json})
    end

    it 'writes an empty report' do
      expect(Gcs::Util).to receive(:write_file).with(Gcs::DEFAULT_DEPENDENCY_REPORT_NAME, {}, Pathname.pwd, nil)

      skip
    end
  end
end
