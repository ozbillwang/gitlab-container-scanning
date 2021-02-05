# frozen_string_literal: true

RSpec.describe Gcs::Util do

  describe 'writes file to given location' do
    let(:tmp_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry tmp_dir
    end

    specify do
      allow(ENV).to receive(:fetch).with('CI_PROJECT_DIR').and_return(tmp_dir)
      Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, 'test', Gcs::Environment.project_dir)

      expect(fixture_file_content(Pathname.new(tmp_dir).join(Gcs::DEFAULT_REPORT_NAME))).to eq('test')
    end
  end
end