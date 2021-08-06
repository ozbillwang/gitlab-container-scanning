# frozen_string_literal: true

RSpec.describe Gcs::Remediations::Collection do
  let(:remediation_collection) { described_class.new }

  describe '#create_remediation' do
    subject { remediation_collection.create_remediation(converted_vuln, vulnerability) }

    context 'when OS is unsupported' do
      let(:converted_vuln) { nil }
      let(:vulnerability) { nil }

      it 'skips remediation' do
        expect(remediation_collection.remediations).to be_empty
      end
    end
  end
end
