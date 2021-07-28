# frozen_string_literal: true
RSpec.describe Gcs::Scanner do
  describe '.template_file' do
    before do
      my_scanner = Class.new(described_class)
      stub_const('MyScanner', my_scanner)
    end

    it 'returns a path in template/ based on the class name' do
      expect(MyScanner.template_file).to end_with 'lib/template/myscanner.tpl'
    end
  end
end
