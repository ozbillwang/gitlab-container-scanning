# frozen_string_literal: true

RSpec.describe Gcs::Cli do
  let(:arguments) { ['scan', 'ubuntu:latest'] }
  let(:execution) { -> { described_class.start(arguments) } }

  RSpec.shared_examples 'QUIET mode' do
    context 'with QUIET mode' do
      before do
        allow(ENV).to receive(:[]).with('CS_QUIET').and_return(true)
      end

      it 'does not print the results table' do
        expect(Gcs::Util).not_to receive(:write_table)
        expect(execution).not_to terminate
      end
    end
  end

  [Gcs::Trivy, Gcs::Grype].each do |scanner|
    context "with #{scanner}" do
      before do
        allow(Gcs::Environment).to receive(:scanner).and_return(scanner)
        allow(scanner).to receive(:scan_os_packages).and_return([nil, nil, double(success?: true)])
        allow(scanner).to receive(:scan_image).with('ubuntu:latest', 'tmp.json').and_return([nil,
                                                                                             nil,
                                                                                             double(success?: status)])
      end

      context 'when scan fails' do
        let(:status) { false }

        specify do
          expect(execution).to terminate.with_code(1)
        end
      end

      context 'when scan succeeds' do
        let(:status) { true }

        before do
          allow(Gcs::Converter).to receive_message_chain(:new, :convert).and_return({})
          allow(File).to receive(:exist?).with('tmp.json').and_return(true)
          allow(File).to receive(:read).with('tmp.json')
        end

        context 'with invalid allow list file' do
          before do
            allow(File).to receive(:read).and_return('"') # smallest broken yaml
          end

          include_examples 'QUIET mode'

          specify do
            expect(Gcs::Util).to receive(:write_table).with({}, nil)
            expect(Gcs::Util).to receive(:write_file).with(Gcs::DEFAULT_REPORT_NAME, {}, Pathname.pwd, nil)
            expect(Gcs.logger).to receive(:debug).with(match(/Allowlist failed with /))
            expect(execution).not_to terminate
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
            expect(Gcs.logger).to receive(:info)
            expect(Gcs.logger).to receive(:info).with(match(/Using allowlist /))
            expect(execution).not_to terminate
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
            expect(execution).not_to terminate
          end
        end
      end
    end
  end
end
