# frozen_string_literal: true
RSpec.shared_context 'with scanner' do
  subject { runner.report_for(type: 'container-scanning') }

  let(:pwd) { Pathname.new(File.dirname(__FILE__)).join('../../..') }

  around do |example|
    runner.mount(dir: project_fixture)
    runner.scan(env: env)
    example.run
  ensure
    runner.cleanup
  end
end
