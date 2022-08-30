# frozen_string_literal: true
RSpec.describe Gcs::Config do
  let(:configurable) { Class.new { include Gcs::Config } }

  subject(:config) { configurable.new }

  describe "#resolve" do
    it "resolves" do
      expect(config.resolve("A", "B", env: { "A" => "foo" })).to eq("foo")
    end

    context "with absent key" do
      it "returns nil" do
        expect(config.resolve("A", "B", env: {})).to be(nil)
      end
    end

    it "accepts default values" do
      expect(config.resolve("A", env: {}, default: :ok)).to be(:ok)
    end

    it "accepts default blocks" do
      expect(config.resolve("A", env: {}) { :ok }).to be(:ok)
    end
  end

  describe "#resolve!" do
    it "resolves" do
      expect(config.resolve!("A", "B", env: { "B" => "bar" })).to eq("bar")
    end

    context "with absent key" do
      it "exits" do
        expect(config).to receive(:exit_with_error_message)
        config.resolve!("A", "B", env: {})
      end
    end
  end
end
