# frozen_string_literal: true
RSpec.describe Gcs::Converter do
  let(:trivy_output_alpine) { fixture_file_content('trivy-alpine.json') }
  let(:trivy_output_centos) { fixture_file_content('trivy-centos.json') }
  let(:trivy_output_debian) { fixture_file_content('trivy-debian.json') }
  let(:trivy_output_with_language) { fixture_file_content('trivy-with-language.json') }
  let(:grype_output_with_language) { fixture_file_content('grype-with-language.json') }
  let(:trivy_output_unsupported_os) { fixture_file_content('trivy-unsupported-os.json') }
  let(:scan_runtime) { { start_time: "2021-09-15T08:36:08", end_time: "2021-09-15T08:36:25" } }

  before(:all) do
    setup_schemas!
  end

  modify_environment 'CS_DEFAULT_BRANCH_IMAGE' => 'registry.example.com/group/project:latest'

  before do
    # Disable remediation to avoid tampering with local Dockerfile
    allow(Gcs::Environment).to receive(:docker_file).and_return(Pathname.new(''))
  end

  describe '#convert' do
    it 'converts into valid format for alpine' do
      gitlab_format = described_class.new(trivy_output_alpine, scan_runtime).convert

      expect(gitlab_format).to match_schema(:container_scanning)
    end

    it 'converts into valid format for centos' do
      gitlab_format = described_class.new(trivy_output_centos, scan_runtime).convert

      expect(gitlab_format).to match_schema(:container_scanning)
    end

    it 'converts into valid format for debian based images' do
      gitlab_format = described_class.new(trivy_output_debian, scan_runtime).convert

      expect(gitlab_format).to match_schema(:container_scanning)
    end

    context 'when there are unsupported operating systems' do
      let(:remediation_collection) { double(Gcs::Remediations::Collection).as_null_object }
      let(:unsupported_operating_systems) { double(Set, empty?: false) }

      it 'shows the unsupported OS warning' do
        allow(Gcs::Remediations::Collection).to receive(:new).and_return(remediation_collection)
        allow(remediation_collection).to receive(:unsupported_operating_systems)
                                           .and_return(unsupported_operating_systems)
        allow(remediation_collection).to receive(:unsupported_os_warning)

        expect(remediation_collection).to receive(:unsupported_os_warning)

        described_class.new(trivy_output_unsupported_os, {}).convert
      end
    end

    context 'when image is not provided in vulnerability' do
      it 'sets provided image_name' do
        gitlab_format = described_class.new(trivy_output_with_language, scan_runtime.merge(image_name: 'g:0.1')).convert

        expect(gitlab_format.dig('vulnerabilities', 0, 'location', 'image')).to eq('g:0.1')
      end
    end

    context 'when language specific scan is enabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(false)
      end

      context 'when vulnerability has language information' do
        it 'returns all vulnerabilities' do
          gitlab_format = described_class.new(grype_output_with_language, scan_runtime).convert

          expect(gitlab_format['vulnerabilities'].size).to eq(30)
        end
      end

      context 'when vulnerability does not have language information' do
        it 'returns all vulnerabilities' do
          gitlab_format = described_class.new(trivy_output_alpine, scan_runtime).convert

          expect(gitlab_format['vulnerabilities'].size).to eq(76)
        end
      end
    end

    context 'when language specific scan is disabled' do
      before do
        allow(Gcs::Environment).to receive(:language_specific_scan_disabled?).and_return(true)
      end

      context 'when vulnerability has language information' do
        it 'returns only OS vulnerabilities' do
          gitlab_format = described_class.new(grype_output_with_language, scan_runtime).convert

          expect(gitlab_format['vulnerabilities'].size).to eq(0)
        end
      end

      context 'when vulnerability does not have language information' do
        it 'returns all vulnerabilities' do
          gitlab_format = described_class.new(trivy_output_alpine, scan_runtime).convert

          expect(gitlab_format['vulnerabilities'].size).to eq(76)
        end
      end
    end

    context 'when default_branch_image is invalid' do
      modify_environment 'CS_DEFAULT_BRANCH_IMAGE' => 'https://registry.example.com/group/project?foo=bar'

      it 'passes schema validation' do
        gitlab_format = described_class.new(trivy_output_alpine, scan_runtime).convert
        expect(gitlab_format).to match_schema(:container_scanning)
      end
    end
  end
end
