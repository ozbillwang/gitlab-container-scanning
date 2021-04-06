# frozen_string_literal: true

RSpec.describe Gcs::Util do
  let (:report) { fixture_file_json_content('report.json') }
  let (:allow_list) { fixture_file_yaml_content('general-allowlist.yml') }

  describe 'writes file to given location' do
    let(:tmp_dir) { Dir.mktmpdir }

    subject { Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, report, Gcs::Environment.project_dir, allow_list) }

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
        expect(fixture_file_content(Pathname.new(tmp_dir).join(Gcs::DEFAULT_REPORT_NAME))).to match(/CVE-2019-3462/)
      end
    end

    %w(general-allowlist image-allowlist image-sha-allowlist).each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file_yaml_content("#{context}.yml") }

        specify do
          expect(fixture_file_content(Pathname.new(tmp_dir).join(Gcs::DEFAULT_REPORT_NAME))).not_to match(/CVE-2019-3462/)
        end
      end
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

    %w(general-allowlist image-allowlist image-sha-allowlist).each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file_yaml_content("#{context}.yml") }

        specify do
          expect{subject}.to output(/Approved/).to_stdout
        end
      end
    end
  end

  describe '.update_allow_list' do

    before do
      Gcs::Util.update_allow_list(allow_list)
    end

    context 'without allow_list' do
      let(:allow_list) { nil }

      specify do
        expect(Gcs::Util.instance_variable_get(:@allow_list_cve)).to include(general: nil, images: nil)
      end
    end

    context 'with general allow list only' do
      specify do
        expect(Gcs::Util.instance_variable_get(:@allow_list_cve)).to include(general: {"CVE-2019-3462"=>"apt"}, images: nil)
      end
    end

    context 'with image-based allow list only' do
      let(:allow_list) { fixture_file_yaml_content('image-allowlist.yml') }

      specify do
        expect(Gcs::Util.instance_variable_get(:@allow_list_cve)).to include(general: nil, images: {"192.168.2.12:5000/root/webgoat-8.0"=>{"CVE-2019-3462"=>"apt"}})
      end
    end

    context 'with image-based&sha256 allow list only' do
      let(:allow_list) { fixture_file_yaml_content('image-sha-allowlist.yml') }

      specify do
        expect(Gcs::Util.instance_variable_get(:@allow_list_cve)).to include(general: nil, images: {"192.168.2.12:5000/root/webgoat-8.0@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e"=>{"CVE-2019-3462"=>"apt"}})
      end
    end

    context 'with both allow lists' do
      let(:allow_list) { fixture_file_yaml_content('vulnerability-allowlist.yml') }

      specify do
        expect(Gcs::Util.instance_variable_get(:@allow_list_cve)).to include(general: {"CVE-2019-3462"=>"apt"}, images: {"192.168.2.12:5000/root/webgoat-8.0@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e"=>{"CVE-2019-3462"=>"apt"}})
      end
    end
  end

  describe '.is_allowed?' do
    subject {Gcs::Util.is_allowed?(report['vulnerabilities'].first)}

    before do
      Gcs::Util.update_allow_list(allow_list)
    end

    context 'without allow_list' do
      let(:allow_list) { nil }

      specify do
        expect(subject).to be false
      end
    end

    %w(general-allowlist image-allowlist image-sha-allowlist).each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file_yaml_content("#{context}.yml") }

        specify do
          expect(subject).to be true
        end

        context 'with missing cve' do
          before do
            report['vulnerabilities'].map!{|vuln| vuln.delete('cve'); vuln }
          end
  
          specify do
            expect(subject).to be false
          end
        end

        context 'with missing package_name' do
          before do
            report['vulnerabilities'].map!{|vuln| vuln['location']['dependency'].delete('package'); vuln }
          end
  
          specify do
            expect(subject).to be false
          end
        end

        context 'with a different cve' do
          before do
            report['vulnerabilities'].map!{|vuln| vuln['cve'][0] = 'A'; vuln }
          end
  
          specify do
            expect(subject).to be false
          end
        end
      end
    end

    context 'with image-based allow_list only' do
      let(:allow_list) { fixture_file_yaml_content('image-allowlist.yml') }

      context 'with missing docker image' do
        before do
          report['vulnerabilities'].map!{|vuln| vuln['location'].delete('image'); vuln }
        end

        specify do
          expect(subject).to be false
        end
      end

      context 'with a different package_name' do
        before do
          report['vulnerabilities'].map!{|vuln| vuln['location']['dependency']['package']['name'] = 'unzip'; vuln }
        end

        specify do
          expect(subject).to be false
        end
      end
    end

    context 'with image-based&sha256 allow_list only' do
      let(:allow_list) { fixture_file_yaml_content('image-sha-allowlist.yml') }

      context 'with missing docker image' do
        before do
          report['vulnerabilities'].map!{|vuln| vuln['location'].delete('image'); vuln }
        end

        specify do
          expect(subject).to be false
        end
      end

      context 'with a docker image with a different sha256' do
        before do
          report['vulnerabilities'].map!{|vuln| vuln['location']['image'].gsub!(/\S\s\(/,'A ('); vuln }
        end

        specify do
          expect(subject).to be false
        end
      end
    end

    context 'with all allow_list types' do
      let(:allow_list) { fixture_file_yaml_content('vulnerability-allowlist.yml') }

      specify do
        expect(subject).to be true
      end
    end
  end
end