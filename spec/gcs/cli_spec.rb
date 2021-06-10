# frozen_string_literal: true

RSpec.describe Gcs::Cli do
  let(:arguments) { ['scan', 'ubuntu:latest'] }
  let(:execution) { -> { described_class.start(arguments) } }

  [Gcs::Trivy, Gcs::Grype].each do |scanner|
    before do
      allow(Gcs::Environment).to receive(:scanner).and_return(scanner)
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

      context 'with allow list file' do
        let(:allow_list_file) { fixture_file('vulnerability-allowlist.yml').to_s }

        before do
          allow(File).to receive(:exist?).with(allow_list_file).and_return(true)
          allow(File).to receive(:read).with(allow_list_file).and_call_original
          allow(Gcs::Environment).to receive(:allow_list_file_path).and_return(allow_list_file)
        end

        specify do
          expect(Gcs::Util).to receive(:write_table).with({}, fixture_file_yaml_content('vulnerability-allowlist.yml'))
          expect(Gcs::Util).to receive(:write_file).with('gl-container-scanning-report.json',
                                                         {},
                                                         Pathname.pwd,
                                                         fixture_file_yaml_content('vulnerability-allowlist.yml'))
          expect(execution).not_to terminate
        end
      end

      context 'without allow list file' do
        before do
          allow(File).to receive(:exist?).with('nonexisting-file-allowlist.yml').and_return(false)
          allow(Gcs::Environment).to receive(:allow_list_file_path).and_return('nonexisting-file-allowlist.yml')
        end

        specify do
          expect(Gcs::Util).to receive(:write_table).with({}, nil)
          expect(Gcs::Util).to receive(:write_file).with('gl-container-scanning-report.json', {}, Pathname.pwd, nil)
          expect(execution).not_to terminate
        end
      end
    end
  end
end
