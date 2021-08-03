# frozen_string_literal: true
RSpec.describe Gcs::AllowList do
  let(:report) { fixture_file_json_content('report.json') }
  let(:allow_list) { fixture_file('general-allowlist.yml') }

  describe '.file_path' do
    let(:project_dir) { 'gitlab/my_project' }

    it 'returns allow list file within the project path' do
      allow(Gcs::Environment).to receive(:project_dir).and_return(project_dir)

      expect(described_class.file_path).to eq(File.join(project_dir, 'vulnerability-allowlist.yml'))
      expect(Gcs::Environment).to have_received(:project_dir).once
    end
  end

  describe '#initialize' do
    let(:docker_img) { "192.168.2.12:5000/root/webgoat-8.0" }
    let(:docker_img_sha) { "#{docker_img}@sha256:bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e" }

    subject { described_class.new(allow_list) }

    context 'with general allow list only' do
      specify do
        expect(subject.instance_variable_get(:@allow_list_cve)).to include(general: {
                                                                             "CVE-2019-3462" => "apt"
                                                                           }, images: nil)
      end
    end

    context 'with image-based allow list only' do
      let(:allow_list) { fixture_file('image-allowlist.yml') }

      specify do
        expect(subject.instance_variable_get(:@allow_list_cve)).to include(
          general: nil,
          images: {
            docker_img => {
              "CVE-2019-3462" => "apt"
            }
          })
      end
    end

    context 'with image-based&sha256 allow list only' do
      let(:allow_list) { fixture_file('image-sha-allowlist.yml') }

      specify do
        expect(subject.instance_variable_get(:@allow_list_cve)).to include(
          general: nil,
          images: {
            docker_img_sha => {
              "CVE-2019-3462" => "apt"
            }
          })
      end
    end

    context 'with both allow lists' do
      let(:allow_list) { fixture_file('vulnerability-allowlist.yml') }

      specify do
        expect(subject.instance_variable_get(:@allow_list_cve)).to include(
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

  describe '#allowed?' do
    subject { described_class.new(allow_list).allowed?(report['vulnerabilities'].first) }

    %w[general-allowlist image-allowlist image-sha-allowlist].each do |context|
      context "with #{context}" do
        let(:allow_list) { fixture_file("#{context}.yml") }

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
      let(:allow_list) { fixture_file('image-allowlist.yml') }

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
      let(:allow_list) { fixture_file('image-sha-allowlist.yml') }

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
      let(:allow_list) { fixture_file('vulnerability-allowlist.yml') }

      specify do
        expect(subject).to be true
      end
    end
  end
end
