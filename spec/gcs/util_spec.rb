# frozen_string_literal: true

RSpec.describe Gcs::Util do
  let(:report) { fixture_file_json_content('report.json') }
  let(:allow_list) { fixture_file_allow_list('general-allowlist.yml') }

  describe 'writes file to given location' do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:full_path) { Pathname.new(tmp_dir).join(Gcs::DEFAULT_REPORT_NAME) }

    subject { described_class.write_file(Gcs::DEFAULT_REPORT_NAME, report, Gcs::Environment.project_dir, allow_list) }

    before do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return(tmp_dir)
      subject
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

    %w[general-allowlist image-allowlist image-sha-allowlist].each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file_allow_list("#{context}.yml") }

        specify do
          expect(fixture_file_content(full_path)).not_to match(/CVE-2019-3462/)
        end
      end
    end
  end

  describe '.write_table' do
    subject { described_class.write_table(report, allow_list) }

    context 'without allow list' do
      let(:allow_list) { nil }

      specify do
        expect { subject }.to output(/unapproved/i).to_stdout
      end
    end

    context 'with QUIET mode' do
      let(:allow_list) { nil }

      specify do
        allow(ENV).to receive(:[]).with('CS_QUIET').and_return(true)

        expect { subject }.not_to output(/unapproved/i).to_stdout
      end
    end

    %w[general-allowlist image-allowlist image-sha-allowlist].each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file_allow_list("#{context}.yml") }

        specify do
          expect { subject }.to output(/Approved/).to_stdout
        end
      end
    end
  end
end
