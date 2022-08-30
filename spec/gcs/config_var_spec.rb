# frozen_string_literal: true
RSpec.describe Gcs::ConfigVar do
  let(:obj) { Object.new }

  subject(:value) { described_class.new(env_vars, default).value(env) }

  describe "#value" do
    using RSpec::Parameterized::TableSyntax

    where(:env_vars, :default, :env, :result) do
      []         | ref(:obj)     | {}               | ref(:obj)
      []         | nil           | {}               | nil
      ["A"]      | ref(:obj)     | {}               | ref(:obj)
      ["A"]      | nil           | { "A" => "foo" } | "foo"
      %w[A B]    | nil           | { "B" => "foo" } | "foo"
      ["A"]      | -> { :ok }    | {}               | :ok
    end

    with_them do
      specify { expect(value).to eq(result) }
    end
  end
end
