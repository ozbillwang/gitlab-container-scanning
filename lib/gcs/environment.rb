module Gcs
  class Environment
    class << self
      def default_docker_image
        return ENV['DOCKER_IMAGE'] unless ENV['DOCKER_IMAGE'].nil?

        application_repository = ENV.fetch('CI_APPLICATION_REPOSITORY') { default_application_repository }
        application_tag = ENV.fetch('CI_APPLICATION_TAG') { default_docker_tag }

        "#{application_repository.strip}:#{application_tag.strip}"
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
        ENV['CONSOLE_LEVEL'] = log_level
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
