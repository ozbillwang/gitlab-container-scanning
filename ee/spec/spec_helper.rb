# frozen_string_literal: true
require 'gcs'
require 'json_schemer'
require 'rspec-parameterized'

require './spec/helpers'
require './spec/support/environment_helper'
require './spec/support/fixture_file_helper'
require './spec/support/schema_helper'
require './spec/support/matchers/match_schema'

RSpec.configure do |config|
  config.include FixtureFileHelper
  config.include EnvironmentHelper
  config.extend EnvironmentHelper::ClassMethods
  config.include SchemaHelper
end
