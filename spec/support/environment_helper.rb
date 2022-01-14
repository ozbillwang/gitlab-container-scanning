# frozen_string_literal: true

require 'climate_control'

module EnvironmentHelper
  module ClassMethods
    def modify_environment(options)
      around do |example|
        ClimateControl.modify(options) do
          example.run
        end
      end
    end
  end

  def with_modified_environment(options, &block)
    ClimateControl.modify(options, &block)
  end
end
