# frozen_string_literal: true
RSpec.describe Gcs::Converter do
  let(:fixture_file_path) { 'trivy-alpine.json' }
  let(:scanner_output) { fixture_file_content(fixture_file_path) }
  let(:options) { { start_time: "2021-09-15T08:36:08", end_time: "2021-09-15T08:36:25" } }
  let(:gitlab_format) { described_class.new(scanner_output, options).convert }

  before(:all) do
    setup_schemas!
  end

  modify_environment 'CS_DEFAULT_BRANCH_IMAGE' => 'registry.example.com/group/project:latest'

  before do
    # Disable remediation to avoid tampering with local Dockerfile
    allow(Gcs::Environment).to receive(:docker_file).and_return(Pathname.new(''))
  end

  describe '#convert' do
    using RSpec::Parameterized::TableSyntax

    where(:fixture_file_path, :expected_vulnerabilities) do
      'trivy-alpine.json'         | 76
      'trivy-centos.json'         | 188
      'trivy-debian.json'         | 91
      'trivy-unsupported-os.json' | 2
    end

    with_them do
      it 'passes schema validation' do
        expect(gitlab_format).to match_schema(:container_scanning)
      end

      it 'has expected number of vulnerabilites' do
        expect(gitlab_format['vulnerabilities'].size).to eq(expected_vulnerabilities)
      end
    end

    context 'when image is not provided in vulnerability' do
      let(:fixture_file_path) { 'trivy-with-language.json' }
      let(:options) do
        {
          start_time: "2021-09-15T08:36:08",
          end_time: "2021-09-15T08:36:25",
          image_name: 'g:0.1'
        }
      end

      it 'sets provided image_name' do
        expect(gitlab_format.dig('vulnerabilities', 0, 'location', 'image')).to eq('g:0.1')
      end
    end

    context 'when language specific scan is enabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      context 'when vulnerability has language information' do
        let(:fixture_file_path) { 'grype-with-language.json' }

        it 'passes schema validation' do
          expect(gitlab_format).to match_schema(:container_scanning)
        end

        it 'returns all vulnerabilities' do
          expect(gitlab_format['vulnerabilities'].size).to eq(30)
        end
      end

      context 'when vulnerability does not have language information' do
        it 'passes schema validation' do
          expect(gitlab_format).to match_schema(:container_scanning)
        end

        it 'returns all vulnerabilities' do
          expect(gitlab_format['vulnerabilities'].size).to eq(76)
        end
      end
    end

    context 'when language specific scan is disabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(true)
      end

      context 'when vulnerability has language information' do
        let(:fixture_file_path) { 'grype-with-language.json' }

        it 'passes schema validation' do
          expect(gitlab_format).to match_schema(:container_scanning)
        end

        it 'returns only OS vulnerabilities' do
          expect(gitlab_format['vulnerabilities'].size).to eq(0)
        end
      end

      context 'when vulnerability does not have language information' do
        it 'passes schema validation' do
          expect(gitlab_format).to match_schema(:container_scanning)
        end

        it 'returns all vulnerabilities' do
          expect(gitlab_format['vulnerabilities'].size).to eq(76)
        end
      end
    end

    context 'when default_branch_image is invalid' do
      modify_environment 'CS_DEFAULT_BRANCH_IMAGE' => 'https://registry.example.com/group/project?foo=bar'

      it 'passes schema validation' do
        expect(gitlab_format).to match_schema(:container_scanning)
      end
    end
  end
end
