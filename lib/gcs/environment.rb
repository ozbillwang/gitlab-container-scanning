module Gcs
  class Environment
    class << self
      def default_docker_image
        return ENV['DOCKER_IMAGE'] unless ENV['DOCKER_IMAGE'].nil?

        application_repository = ENV.fetch('CI_APPLICATION_REPOSITORY') { default_application_repository }
        application_tag = ENV.fetch('CI_APPLICATION_TAG') { default_docker_tag }

        "#{application_repository.strip}:#{application_tag.strip}"
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
