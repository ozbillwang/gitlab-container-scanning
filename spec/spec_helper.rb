require 'bundler/setup'
require 'gcs'
require 'json'
require 'dry/schema'
require 'json-schema'
require 'securerandom'
# require 'rspec-benchmark'
require 'helpers'
require 'support/fixture_file_helper'
# require 'support/report'
# require 'support/project_helper'
# require 'support/integration_test_helper'
# require 'support/matchers'
# require 'support/proxy_helper'
# require 'support/shared'

# RSpec.configure do |config|
#   # Enable flags like --only-failures and --next-failure
#   config.example_status_persistence_file_path = ".rspec_status"

#   # Disable RSpec exposing methods globally on `Module` and `main`
#   config.disable_monkey_patching!

#   config.expect_with :rspec do |c|
#     c.syntax = :expect
#   end
# end


RSpec.configure do |config|
  # config.include RSpec::Benchmark::Matchers
  config.include FixtureFileHelper
  # config.include Helpers
  # config.include IntegrationTestHelper, type: :integration
  config.define_derived_metadata(file_path: %r{/spec/integration}) do |metadata|
    metadata[:type] = :integration
  end
  config.after(:example, type: :integration) do
    runner.cleanup
  end
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
