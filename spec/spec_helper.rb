# frozen_string_literal: true

require 'bundler/setup'
require 'gcs'
require 'json'
require 'uri'
require 'json_schemer'
require 'securerandom'
require 'helpers'
require 'singleton'
require 'webmock/rspec'
require 'rspec-parameterized'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.define_derived_metadata(file_path: %r{/spec/integration}) do |metadata|
    metadata[:type] = :integration
  end

  config.define_derived_metadata(file_path: %r{/spec/integration/network}) do |metadata|
    metadata[:type] = :network
  end

  config.include ProxyHelper, type: :network
  config.include IntegrationTestHelper
  config.include FixtureFileHelper
  config.include ExitCodeMatchers
  config.include SchemaHelper

  config.before(:all, type: :network) do
    ProxyServer.instance.start
  end

  config.after(:all, type: :network) do
    ProxyServer.instance.stop
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = false
  config.order = :random
  Kernel.srand config.seed
end
