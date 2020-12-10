# frozen_string_literal: true

require 'bundler/setup'
require 'gcs'
require 'json'
require 'json-schema'
require 'dry/schema'
require 'json-schema'
require 'securerandom'
require 'helpers'
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.include FixtureFileHelper
  config.include ExitCodeMatchers
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = false
  config.order = :random
  Kernel.srand config.seed
end
