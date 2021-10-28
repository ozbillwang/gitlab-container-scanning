# frozen_string_literal: true
module Gcs
  class Environment
    class << self
      def docker_image
        return ENV['DOCKER_IMAGE'] unless ENV['DOCKER_IMAGE'].nil?

        default_docker_image
      end

      def default_branch_image
        image = ENV.fetch('CS_DEFAULT_BRANCH_IMAGE', nil)

        return image if image

        "#{registry_image}/#{default_branch}:#{application_tag}"
      end

      def default_docker_image
        "#{application_repository}:#{application_tag}"
      end

      def project_dir
        pd = ENV.fetch('CI_PROJECT_DIR') { Pathname.pwd }
        if pd.is_a?(String)
          return Pathname.new(pd) if Pathname.new(pd).exist?

          return Pathname.pwd
        end

        pd
      end

      def docker_file
        docker_file = ENV.fetch('DOCKERFILE_PATH', "#{project_dir}/Dockerfile")
        Pathname.new(docker_file)
      end

      def setup
        setup_log_level
      end

      def severity_level_name
        threshold = ENV['CS_SEVERITY_THRESHOLD']

        return 'UNKNOWN' if threshold.nil?

        threshold.upcase.strip
      end

      def docker_registry_credentials
        username = ENV.fetch('DOCKER_USER') { ENV['CI_REGISTRY_USER'] if should_use_ci_credentials? }
        password = ENV.fetch('DOCKER_PASSWORD') { ENV['CI_REGISTRY_PASSWORD'] if should_use_ci_credentials? }

        return if username.nil? || username.empty? || password.nil? || password.empty?

        { "username" => username, "password" => password }
      end

      def docker_registry_security_config
        docker_insecure = ENV.fetch('CS_DOCKER_INSECURE', 'false').to_s.casecmp?("true")
        registry_insecure = ENV.fetch('CS_REGISTRY_INSECURE', 'false').to_s.casecmp?("true")

        { docker_insecure: docker_insecure, registry_insecure: registry_insecure }
      end

      def scanner
        scanner = ENV.fetch('SCANNER', 'trivy')
        Object.const_get("Gcs::#{scanner.capitalize}")
      rescue NameError
        Gcs.logger.error("Invalid scanner '#{scanner}'")
        exit 1
      end

      def log_level
        ENV.fetch('SECURE_LOG_LEVEL', 'info').downcase
      end

      def ubi?
        File.exist?('/etc/redhat-release')
      end

      private

      def should_use_ci_credentials?
        return false if ENV['CI_REGISTRY'].nil? || ENV['CI_REGISTRY'].empty?

        docker_image.start_with? "#{ENV['CI_REGISTRY']}/"
      end

      def setup_log_level
        Gcs.logger.level = log_level.upcase
      end

      def application_repository
        ENV.fetch('CI_APPLICATION_REPOSITORY') { default_application_repository }.strip
      end

      def application_tag
        ENV.fetch('CI_APPLICATION_TAG') { default_docker_tag }.strip
      end

      def default_application_repository
        "#{registry_image}/#{commit_ref_slug}"
      end

      def commit_ref_slug
        fetch_from_env!('CI_COMMIT_REF_SLUG')
      end

      def default_branch
        fetch_from_env!('CI_DEFAULT_BRANCH')
      end

      def default_docker_tag
        fetch_from_env!('CI_COMMIT_SHA')
      end

      def registry_image
        fetch_from_env!('CI_REGISTRY_IMAGE')
      end

      def fetch_from_env!(env_var)
        ENV.fetch(env_var).strip
      rescue KeyError => e
        Gcs.logger.error("Environment variable `#{e.key}` was not found and is required for execution")
        exit 1
      end
    end
  end
end
