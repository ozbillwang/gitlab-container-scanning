# frozen_string_literal: true
RSpec.describe Gcs::DependencyListConverter do
  let(:trivy_template) { File.read(Gcs::Trivy.dependencies_template_file) }
  let(:fixture_file_path) { 'trivy-dependencies.json' }
  let(:raw_scanner_output) { fixture_file_content(fixture_file_path) }
  let(:output_dependencies) { raw_scanner_output }
  let(:scan_runtime) { { start_time: '2021-09-15T08:36:08', end_time: '2021-09-15T08:36:25' } }

  subject(:gitlab_format) { described_class.new(trivy_template, output_dependencies, scan_runtime).convert }

  before(:all) do
    setup_schemas!
  end

  describe '#convert' do
    it 'converts into valid format' do
      expect(gitlab_format).to match_schema(:dependency_scanning)
    end

    it 'prepares report with start and end time' do
      expect(gitlab_format.dig('scan', 'start_time')).to eq('2021-09-15T08:36:08')
      expect(gitlab_format.dig('scan', 'end_time')).to eq('2021-09-15T08:36:25')
    end

    it 'prepares report with image path' do
      expect(gitlab_format.dig('dependency_files', 0, 'path')).to eq('container-image:nginx:latest')
    end

    {
      'apk' => ['alpine'],
      'apt' => %w[debian ubuntu],
      'yum' => %w[amazon oracle centos redhat],
      'tdnf' => ['photon'],
      'zypper' => %w[opensuse suse],
      'unknown' => %w[other windows]
    }.each do |pkg_manage, distros|
      distros.each do |distro|
        context "for #{distro} OS" do
          let(:output_dependencies) do
            JSON
              .parse(raw_scanner_output)
              .tap { |parsed_report| parsed_report['Metadata']['OS']['Family'] = distro }
              .to_json
          end

          it 'prepares report with related package manager and os information' do
            expect(gitlab_format.dig('dependency_files', 0, 'package_manager')).to eq("#{distro}:11.1 (#{pkg_manage})")
          end
        end
      end
    end

    it 'prepares report with package manager and os information' do
      expect(gitlab_format.dig('dependency_files', 0, 'package_manager')).to eq('debian:11.1 (apt)')
    end

    it 'prepares report with dependencies' do
      expect(gitlab_format.dig('dependency_files', 0, 'dependencies')).to eq(
        [
          { 'package' => { 'name' => 'adduser' }, 'version' => '3.118' },
          { 'package' => { 'name' => 'apt' }, 'version' => '2.2.4' },
          { 'package' => { 'name' => 'base-files' }, 'version' => '11.1+deb11u1' }
        ]
      )
    end

    context 'when language specific scan is enabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      it 'prepares report with package manager and language information' do
        expect(gitlab_format.dig('dependency_files', 1, 'package_manager')).to eq('Java (jar)')
      end

      it 'prepares report with language dependencies' do
        expect(gitlab_format.dig('dependency_files', 1, 'dependencies')).to eq(
          [
            { 'package' => { 'name' => 'ant:ant' }, 'version' => '1.6.2' }
          ]
        )
      end
    end

    context 'when language specific scan is disabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(true)
      end

      it 'does not prepare report with package manager nor language information' do
        expect(gitlab_format['dependency_files'].size).to eq(1)
        expect(gitlab_format['dependency_files']).not_to include(hash_including('package_manager' => 'Java (jar)'))
      end
    end

    context 'when report does not contain information about installed packages' do
      let(:raw_scanner_output) { fixture_file_content('trivy-scratch-image.json') }

      it 'returns empty dependency report' do
        expect(gitlab_format['dependency_files']).to be_empty
      end
    end
  end
end
