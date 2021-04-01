# frozen_string_literal: true

RSpec.describe Gcs::Util do
  let (:report) do
    {
      'vulnerabilities' => [
        'cve'=> 'CVE-2019-13232', 
        'severity' => 'High', 
        'description' => 'cve description', 
        'location' => {
          'dependency' => {
            'package'=> {
              'name' => 'unzip'
            },
            'version' => '1.0.0'
          }
        }
      ]
    }
  end

  let(:allow_list) { fixture_file_yaml_content('vulnerability-allowlist.yml') }

  describe 'writes file to given location' do
    let(:tmp_dir) { Dir.mktmpdir }

    before do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return(tmp_dir)
    end

    after do
      FileUtils.remove_entry tmp_dir
    end

    specify do
      Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, report, Gcs::Environment.project_dir, nil)

      expect(fixture_file_content(Pathname.new(tmp_dir).join(Gcs::DEFAULT_REPORT_NAME))).to match(/CVE-2019-13232/)
    end

    specify do
      Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, report, Gcs::Environment.project_dir, allow_list)

      expect(fixture_file_content(Pathname.new(tmp_dir).join(Gcs::DEFAULT_REPORT_NAME))).not_to match(/CVE-2019-13232/)
    end
  end

  describe '.write_table' do
    subject { Gcs::Util.write_table(report, allow_list) }

    context 'without allow list' do
      let(:allow_list) { nil }

      specify do
        expect{subject}.to output(/Unapproved/).to_stdout
      end
    end

    context 'with allow list' do
      specify do
        expect{subject}.to output(/Approved/).to_stdout
      end
    end
  end
end