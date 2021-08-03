# frozen_string_literal: true
module Gcs
  class Environment
    class << self
      def docker_image
        return ENV['DOCKER_IMAGE'] unless ENV['DOCKER_IMAGE'].nil?

        default_docker_image
      end

      def default_docker_image
        application_repository = ENV.fetch('CI_APPLICATION_REPOSITORY') { default_application_repository }
        application_tag = ENV.fetch('CI_APPLICATION_TAG') { default_docker_tag }

        "#{application_repository.strip}:#{application_tag.strip}"
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
        docker_file_path = Pathname.new(docker_file)

        unless docker_file_path.exist?
          Gcs.logger.info("Remediation is disabled because #{docker_file_path} cannot be found")
        end

        docker_file_path
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

      def default_application_repository
        "#{ENV.fetch('CI_REGISTRY_IMAGE')}/#{ENV.fetch('CI_COMMIT_REF_SLUG')}"
      rescue KeyError => e
        Gcs.logger.error("Can't find variable #{e.inspect}")
        exit 1
      end

      def default_docker_tag
        ENV.fetch('CI_COMMIT_SHA')
      rescue KeyError => e
        Gcs.logger.error("Can't find variable #{e.inspect}")
        exit 1
      end
    end
  end
end
