# frozen_string_literal: true
module Gcs
  module Config
    def resolve!(*env_vars, default: nil, env: ENV, &block)
      resolve(*env_vars, default: nil, env: env, &block) || exit_with_error_message(env_vars)
    end

    def resolve(*env_vars, default: nil, env: ENV, &block)
      config_var(*env_vars, default || block).value(env)
    end

    private

    def config_var(*env_vars, default)
      ConfigVar.new(env_vars, default)
    end

    def exit_with_error_message(env_vars)
      Gcs.logger.error("None of the environment variables `#{env_vars}` were found but are required for execution")
      exit 1
    end
  end
end
