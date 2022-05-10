# frozen_string_literal: true

RSpec.describe Gcs::Plugin::ContainerScan do
  RSpec.shared_examples 'QUIET mode' do
    context 'with QUIET mode' do
      modify_environment 'CS_QUIET' => 'true'

      it 'does not print the results table' do
        expect(Gcs::Util).not_to receive(:write_table)
      end
    end
  end

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
        expect(Gcs.logger).to receive(:debug).with(match(/Allowlist failed with /))

        convert
      end
    end

    context 'with allow list file' do
      let(:allow_list_file) { fixture_file('vulnerability-allowlist.yml').to_s }

      before do
        allow(Gcs::AllowList).to receive(:file_path).and_return(allow_list_file)
      end

      include_examples 'QUIET mode'

      specify do
        expect(Gcs::Util).to receive(:write_table).with({}, instance_of(Gcs::AllowList))
        expect(Gcs::Util).to receive(:write_file).with(Gcs::DEFAULT_REPORT_NAME, {},
                                                       Pathname.pwd,
                                                       instance_of(Gcs::AllowList))

        expect(Gcs.logger).to receive(:info).with(match(/Using allowlist /))

        convert
      end
    end

    context 'without allow list file' do
      before do
        allow(Gcs::AllowList).to receive(:file_path).and_return('nonexisting-file-allowlist.yml')
      end

      include_examples 'QUIET mode'

      specify do
        expect(Gcs::Util).to receive(:write_table).with({}, nil)
        expect(Gcs::Util).to receive(:write_file).with(Gcs::DEFAULT_REPORT_NAME, {}, Pathname.pwd, nil)
        expect(Gcs.logger).to receive(:debug).with(match(/Allowlist failed with /))

        convert
      end
    end
  end
end
