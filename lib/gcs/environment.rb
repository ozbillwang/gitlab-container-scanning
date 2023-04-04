# frozen_string_literal: true
module Gcs
  class Environment
    class << self
      include Gcs::Config

      def docker_image
        resolve('CS_IMAGE', 'DOCKER_IMAGE') { default_docker_image }
      end

      def default_branch_image
        resolve('CS_DEFAULT_BRANCH_IMAGE')
      end

      def default_docker_image
        "#{application_repository}:#{application_tag}"
      end

      def project_dir
        pd = resolve('CI_PROJECT_DIR') { Pathname.pwd }
        if pd.is_a?(String)
          return Pathname.new(pd) if Pathname.new(pd).exist?

          return Pathname.pwd
        end

        pd
      end

      def docker_file
        docker_file = resolve('CS_DOCKERFILE_PATH', 'DOCKERFILE_PATH') do
          "#{project_dir}/Dockerfile"
        end

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
        username = resolve('CS_REGISTRY_USER', 'DOCKER_USER') do
          ENV['CI_REGISTRY_USER'] if should_use_ci_credentials?
        end

        password = resolve('CS_REGISTRY_PASSWORD', 'DOCKER_PASSWORD') do
          ENV['CI_REGISTRY_PASSWORD'] if should_use_ci_credentials?
        end

        return if username.nil? || username.empty? || password.nil? || password.empty?

        { "username" => username, "password" => password }
      end

      def docker_registry_security_config
        docker_insecure = resolve('CS_DOCKER_INSECURE', default: 'false').to_s.casecmp?("true")
        registry_insecure = resolve('CS_REGISTRY_INSECURE', default: 'false').to_s.casecmp?("true")

        { docker_insecure: docker_insecure, registry_insecure: registry_insecure }
      end

      def scanner
        scanner = resolve('SCANNER', default: 'trivy')
        Object.const_get("Gcs::#{scanner.capitalize}")
      rescue NameError
        Gcs.logger.error("Invalid scanner '#{scanner}'")
        exit 1
      end

      def log_level
        resolve('SECURE_LOG_LEVEL', default: 'info').downcase
      end

      def debug?
        log_level == 'debug'
      end

      def ubi?
        File.exist?('/etc/redhat-release')
      end

      def sbom_enabled?
        resolve('CS_SBOM_ENABLED', default: 'false').to_s.casecmp?('true')
      end

      def fips_enabled?
        resolve('CI_GITLAB_FIPS_MODE', default: 'false').to_s.casecmp?('true')
      end

      def dependency_scan_disabled?
        resolve('CS_DISABLE_DEPENDENCY_LIST', default: 'false').to_s.casecmp?('true')
      end

      def language_specific_scan_disabled?
        resolve('CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN', default: 'true').to_s.casecmp?('true')
      end

      def ignore_unfixed_vulnerabilities?
        resolve('CS_IGNORE_UNFIXED', default: 'false').to_s.casecmp?('true')
      end

      def ee?
        resolve('GITLAB_FEATURES', default: '').to_s.split(',').include?('container_scanning')
      end

      def cs_schema_model
        resolve('CS_SCHEMA_MODEL', default: 14).to_i
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
        resolve('CI_APPLICATION_REPOSITORY') { default_application_repository }.strip
      end

      def application_tag
        resolve('CI_APPLICATION_TAG') { default_docker_tag }.strip
      end

      def default_application_repository
        "#{registry_image}/#{commit_ref_slug}"
      end

      def commit_ref_slug
        resolve!('CI_COMMIT_REF_SLUG')
      end

      def default_branch
        resolve!('CI_DEFAULT_BRANCH')
      end

      def default_docker_tag
        resolve!('CI_COMMIT_SHA')
      end

      def registry_image
        resolve!('CI_REGISTRY_IMAGE')
      end
    end
  end
end
