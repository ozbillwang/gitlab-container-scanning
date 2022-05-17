# frozen_string_literal: true
RSpec.describe Gcs::Converter do
  let(:reports) do
    {
      trivy_alpine: 'trivy-alpine.json',
      trivy_centos: 'trivy-centos.json',
      trivy_debian: 'trivy-debian.json',
      trivy_dependencies: 'trivy-dependencies.json',
      trivy_scratch_image: 'trivy-scratch-image.json',
      trivy_unsupported_os: 'trivy-unsupported-os.json',
      trivy_with_language: 'trivy-with-language.json',
      grype_with_language: 'grype-with-language.json'
    }
  end

  let(:scanner_report) { :trivy_alpine }
  let(:fixture_file_name) { reports[scanner_report] }
  let(:scanner_output) { fixture_file_content(File.join('converter', 'scanner_output', fixture_file_name)) }
  let(:expected_raw) { fixture_file_content(File.join('converter', 'expect', fixture_file_name)) }
  let(:expected) { JSON.parse(expected_raw) }
  let(:options) { { start_time: "2021-09-15T08:36:08", end_time: "2021-09-15T08:36:25" } }

  subject(:gitlab_format) { described_class.new(scanner_output, options).convert }

  before(:all) do
    setup_schemas!
  end

  modify_environment 'CS_DEFAULT_BRANCH_IMAGE' => 'registry.example.com/group/project:latest'

  before do
    # Disable remediation to avoid tampering with local Dockerfile
    allow(Gcs::Environment).to receive(:docker_file).and_return(Pathname.new(''))
  end

  RSpec.shared_examples 'valid conversion' do
    it 'passes schema validation' do
      expect(gitlab_format).to match_schema(:container_scanning)
    end

    it 'matches expected output' do
      expect(gitlab_format).to eq(expected)
    end
  end

  describe '#convert' do
    where(:scanner_report) do
      [
        :trivy_alpine,
        :trivy_centos,
        :trivy_debian,
        :trivy_unsupported_os
      ]
    end

    with_them do
      it_behaves_like 'valid conversion'
    end

    context 'when image is not provided in vulnerability' do
      let(:scanner_report) { :trivy_with_language }

      before do
        options.merge!(image_name: 'g:0.1')
      end

      it 'sets provided image_name' do
        expect(gitlab_format.dig('vulnerabilities', 0, 'location', 'image')).to eq('g:0.1')
      end

      it_behaves_like 'valid conversion'
    end

    context 'when language specific scan is enabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      context 'when using grype with language information' do
        let(:scanner_report) { :grype_with_language }

        # This test is broken and returns 0 vulnerabilities
        it_behaves_like 'valid conversion'
      end

      context 'when using trivy with language information' do
        let(:scanner_report) { :trivy_with_language }

        before do
          options.merge!(image_name: 'g:0.1')
        end

        it 'sets provided image_name' do
          expect(gitlab_format.dig('vulnerabilities', 0, 'location', 'image')).to eq('g:0.1')
        end

        # This test is broken and returns 0 vulnerabilities
        it_behaves_like 'valid conversion'
      end

      context 'when vulnerability does not have language information' do
        it_behaves_like 'valid conversion'
      end
    end

    context 'when language specific scan is disabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(true)
      end

      context 'when vulnerability has language information' do
        let(:scanner_report) { :grype_with_language }

        it_behaves_like 'valid conversion'
      end

      context 'when vulnerability does not have language information' do
        it_behaves_like 'valid conversion'
      end
    end

    context 'when default_branch_image is invalid' do
      modify_environment 'CS_DEFAULT_BRANCH_IMAGE' => 'https://registry.example.com/group/project?foo=bar'

      let(:expected_raw) do
        # Manually created
        fixture_file_content(File.join('converter', 'expect', 'trivy-alpine-without-default-branch-image.json'))
      end

      it_behaves_like 'valid conversion'
    end
  end
end
