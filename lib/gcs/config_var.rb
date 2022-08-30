# frozen_string_literal: true
module Gcs
  class ConfigVar
    def initialize(env_vars, default)
      @env_vars = env_vars
      @default = default
    end

    def value(env)
      env_value(env)&.strip || default_value
    end

    private

    attr_reader :env_vars,
                :default

    def env_value(env)
      env_vars.each do |key|
        return env[key] if env.key?(key)
      end

      nil
    end

    def default_value
      return default unless default.respond_to?(:call)

      default.call
    end
  end
end
