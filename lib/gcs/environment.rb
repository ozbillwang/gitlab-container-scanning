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
        docker_file_path = ENV.fetch('DOCKERFILE_PATH') { 'Dockerfile' }
        if Pathname.new(docker_file_path).exist?
          docker_file_path
        else
          Gcs.logger.error("Can not find Dockerfile in #{docker_file_path}")
        end
      end

      def setup_log_level
        ENV['TRIVY_DEBUG'] = true if log_level == :debug
        # binding.irb
        Gcs.logger.level = log_level.upcase
      end

      private

      def log_level
        ENV.fetch('SECURE_LOG_LEVEL', 'info')
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
