# frozen_string_literal: true

RSpec.describe Gcs::Util do
  let(:report) { fixture_file_json_content('report.json') }
  let(:allow_list) { fixture_file_yaml_content('general-allowlist.yml') }

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
        let(:allow_list) { fixture_file_yaml_content("#{context}.yml") }

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
        expect { subject }.to output(/Unapproved/).to_stdout
      end
    end

    %w[general-allowlist image-allowlist image-sha-allowlist].each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file_yaml_content("#{context}.yml") }

        specify do
          expect { subject }.to output(/Approved/).to_stdout
        end
      end
    end
  end

  describe '.update_allow_list' do
    let(:docker_img) { "192.168.2.12:5000/root/webgoat-8.0" }
    let(:docker_img_sha) { "#{docker_img}@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e" }

    before do
      described_class.update_allow_list(allow_list)
    end

    context 'without allow_list' do
      let(:allow_list) { nil }

      specify do
        expect(described_class.instance_variable_get(:@allow_list_cve)).to include(general: nil, images: nil)
      end
    end

    context 'with general allow list only' do
      specify do
        expect(described_class.instance_variable_get(:@allow_list_cve)).to include(general: {
                                                                                     "CVE-2019-3462" => "apt"
                                                                                   }, images: nil)
      end
    end

    context 'with image-based allow list only' do
      let(:allow_list) { fixture_file_yaml_content('image-allowlist.yml') }

      specify do
        expect(described_class.instance_variable_get(:@allow_list_cve)).to include(
          general: nil,
          images: {
            docker_img => {
              "CVE-2019-3462" => "apt"
            }
          })
      end
    end

    context 'with image-based&sha256 allow list only' do
      let(:allow_list) { fixture_file_yaml_content('image-sha-allowlist.yml') }

      specify do
        expect(described_class.instance_variable_get(:@allow_list_cve)).to include(
          general: nil,
          images: {
            docker_img_sha => {
              "CVE-2019-3462" => "apt"
            }
          })
      end
    end

    context 'with both allow lists' do
      let(:allow_list) { fixture_file_yaml_content('vulnerability-allowlist.yml') }

      specify do
        expect(described_class.instance_variable_get(:@allow_list_cve)).to include(
          general: { "CVE-2019-3462" => "apt" },
          images:
          {
            docker_img_sha => {
              "CVE-2019-3462" => "apt"
            }
          })
      end
    end
  end

  describe '.allowed?' do
    subject { described_class.allowed?(report['vulnerabilities'].first) }

    before do
      described_class.update_allow_list(allow_list)
    end

    context 'without allow_list' do
      let(:allow_list) { nil }

      specify do
        expect(subject).to be false
      end
    end

    %w[general-allowlist image-allowlist image-sha-allowlist].each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file_yaml_content("#{context}.yml") }

        specify do
          expect(subject).to be true
        end

        context 'with missing cve' do
          before do
            report['vulnerabilities'].map! do |vuln|
              vuln.delete('cve')
              vuln
            end
          end

          specify do
            expect(subject).to be false
          end
        end

        context 'with missing package_name' do
          before do
            report['vulnerabilities'].map! do |vuln|
              vuln['location']['dependency'].delete('package')
              vuln
            end
          end

          it 'ignores missing package_name' do
            expect(subject).to be true
          end
        end

        context 'with a different cve' do
          before do
            report['vulnerabilities'].map! do |vuln|
              vuln['cve'][0] = 'A'
              vuln
            end
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
          report['vulnerabilities'].map! do |vuln|
            vuln['location'].delete('image')
            vuln
          end
        end

        specify do
          expect(subject).to be false
        end
      end

      context 'with a different package_name' do
        before do
          report['vulnerabilities'].map! do |vuln|
            vuln['location']['dependency']['package']['name'] = 'unzip'
            vuln
          end
        end

        it 'ignores different package_name' do
          expect(subject).to be true
        end
      end
    end

    context 'with image-based&sha256 allow_list only' do
      let(:allow_list) { fixture_file_yaml_content('image-sha-allowlist.yml') }

      context 'with missing docker image' do
        before do
          report['vulnerabilities'].map! do |vuln|
            vuln['location'].delete('image')
            vuln
          end
        end

        specify do
          expect(subject).to be false
        end
      end

      context 'with a docker image with a different sha256' do
        before do
          report['vulnerabilities'].map! do |vuln|
            vuln['location']['image'].gsub!(/\S\s\(/, 'A (')
            vuln
          end
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
