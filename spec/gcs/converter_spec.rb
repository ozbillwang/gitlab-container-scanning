# frozen_string_literal: true
RSpec.describe Gcs::Converter do
  let(:trivy_output_alpine) { fixture_file_content('trivy-alpine.json') }
  let(:trivy_output_centos) { fixture_file_content('trivy-centos.json') }
  let(:trivy_output_debian) { fixture_file_content('trivy-debian.json') }
  let(:trivy_output_unsupported_os) { fixture_file_content('trivy-unsupported-os.json') }

  describe '#convert' do
    it 'converts into valid format for alpine' do
      gitlab_format = described_class.new(trivy_output_alpine, {}).convert
      result = Schema::ReportSchema.call(gitlab_format)
      expect(result).to be_success
    end

    it 'converts into valid format for centos' do
      gitlab_format = described_class.new(trivy_output_centos, {}).convert
      result = Schema::ReportSchema.call(gitlab_format)
      expect(result).to be_success
    end

    it 'converts into valid format for debian based images' do
      gitlab_format = described_class.new(trivy_output_debian, {}).convert
      result = Schema::ReportSchema.call(gitlab_format)
      expect(result).to be_success
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
  end
end
