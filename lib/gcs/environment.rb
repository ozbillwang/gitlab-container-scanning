# frozen_string_literal: true
module Gcs
  class Environment
    ALLOW_LIST_FILENAME = "vulnerability-allowlist.yml"

    class << self
      def default_docker_image
        return ENV['DOCKER_IMAGE'] unless ENV['DOCKER_IMAGE'].nil?

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

      def allow_list_file_path
        "#{project_dir}/#{ALLOW_LIST_FILENAME}"
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
        # TODO abstract this further when Grype variables introduced
        setup_trivy_docker_registy
        setup_log_level
      end

      def setup_trivy_docker_registy
        username = ENV.fetch('DOCKER_USER') { ENV['CI_REGISTRY_USER'] }
        password = ENV.fetch('DOCKER_PASSWORD') { ENV['CI_REGISTRY_PASSWORD'] }

        return if username.nil? || username.empty? || password.nil? || password.empty?

        ENV['TRIVY_USERNAME'] = username
        ENV['TRIVY_PASSWORD'] = password
      end

      def setup_log_level
        ENV['TRIVY_DEBUG'] = trivy_debug_value
        Gcs.logger.level = log_level.upcase
      end

      def scanner
        scanner = ENV.fetch('SCANNER', 'trivy')
        Object.const_get("Gcs::#{scanner.capitalize}")
      rescue NameError
        Gcs.logger.error("Invalid scanner '#{scanner}'")
        exit 1
      end

      private

      def log_level
        ENV.fetch('SECURE_LOG_LEVEL', 'info')
      end

      def trivy_debug_value
        'true' if log_level == 'debug'
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
