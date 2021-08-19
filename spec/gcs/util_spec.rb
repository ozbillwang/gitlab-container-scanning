# frozen_string_literal: true

RSpec.describe Gcs::Util do
  let(:report) { fixture_file_json_content('report.json') }
  let(:allow_list) { double(Gcs::AllowList, allowed?: true) }

  describe 'writes file to given location' do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:full_path) { Pathname.new(tmp_dir).join(Gcs::DEFAULT_REPORT_NAME) }

    subject(:write_file) do
      described_class.write_file(Gcs::DEFAULT_REPORT_NAME, report, Gcs::Environment.project_dir, allow_list)
    end

    before do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return(tmp_dir)
      write_file
    end

    after do
      FileUtils.remove_entry tmp_dir
    end

    context 'without allow list' do
      let(:allow_list) { nil }

      specify do
        expect(fixture_file_content(full_path)).to match(/CVE-2019-3462/)
      end
    end

    context 'with allow list' do
      specify do
        expect(fixture_file_content(full_path)).not_to match(/CVE-2019-3462/)
      end
    end
  end

  describe '.write_table' do
    subject(:write_table) { described_class.write_table(report, allow_list) }

    context 'without allow list' do
      let(:allow_list) { nil }

      specify do
        expect { write_table }.to output(/unapproved/i).to_stdout
      end
    end

    context 'with allow list' do
      specify do
        expect { write_table }.to output(/Approved/).to_stdout
      end
    end
  end
end
