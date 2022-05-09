# frozen_string_literal: true
RSpec.describe Gcs::Converter do
  let(:trivy_output_unsupported_os) { fixture_file_content('trivy-unsupported-os.json') }

  describe '#convert' do
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
