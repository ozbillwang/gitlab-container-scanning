# frozen_string_literal: true
module Gcs
  class Scanner
    class << self
      def template_file
        File.join(Gcs.lib, 'template', "#{scanner_name.downcase}.tpl").to_s
      end

      def dependencies_template_file
        File.join(Gcs.lib, 'template', "dependencies-#{scanner_name.downcase}.json")
      end

      def scan_image(image_name, output_file_name)
        return ['', fips_mode_with_docker_registry_info, nil] if fips_mode_with_docker_registry?

        disabled_remediation_info unless Gcs::Environment.docker_file.exist?
        Gcs.logger.info(log_message(image_name))
        stdout, stderr, status = Gcs.shell.execute(scan_command(image_name, output_file_name), environment)

        [stdout, improve_stderr_msg(stderr, image_name), status]
      end

      def scan_os_packages_supported?
        # Scanner class must implement scan_os_packages_supported? and os_scan_command methods when this is supported
        false
      end

      def scan_os_packages(image_name, output_file_name)
        Gcs.logger.info(log_message(image_name))
        stdout, stderr, status = Gcs.shell.execute(os_scan_command(image_name, output_file_name), environment)

        [stdout, improve_stderr_msg(stderr, image_name), status]
      end

      private

      def scanner_name
        name.split('::').last
      end

      def fips_mode_with_docker_registry?
        Gcs::Environment.fips_enabled? && !Gcs::Environment.docker_registry_credentials.nil?
      end

      def fips_mode_with_docker_registry_info
        <<~EOMSG
          FIPS mode is not supported when scanning authenticated registries. CS_REGISTRY_USER and CS_REGISTRY_PASSWORD must not \
          be set while FIPS mode is enabled.
        EOMSG
      end

      def disabled_remediation_info
        Gcs.logger.info(
          <<~EOMSG
          Remediation is disabled; #{Gcs::Environment.docker_file} cannot be found. Have you set `GIT_STRATEGY` and
          `CS_DOCKERFILE_PATH`?
          See https://docs.gitlab.com/ee/user/application_security/container_scanning/#solutions-for-vulnerabilities-auto-remediation
        EOMSG
        )
      end

      def log_message(image_name)
        <<~HEREDOC
            Scanning container from registry #{image_name} \
            for vulnerabilities with severity level #{Gcs::Environment.severity_level_name} or higher, \
            with gcs #{Gcs::VERSION} and #{scanner_name} #{scanner_version}, advisories updated at #{db_updated_at}
        HEREDOC
      end

      def improve_stderr_msg(stderr, image_name)
        return unless stderr

        if invalid_credentials?(stderr)
          "The credentials set in CS_REGISTRY_USER and CS_REGISTRY_PASSWORD are either empty or not valid. " \
          "Please set valid credentials."
        elsif image_not_found?(stderr)
          "The image #{image_name} could not be found. " \
          "To change the image being scanned, use the CS_IMAGE environment variable. " \
          "For details, see https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables"
        elsif manifest_v1?(stderr)
          "This image cannot be scanned because it is stored in the registry using manifest version 2, schema 1. " \
          "This schema version is deprecated and is not supported. Use a different image, or upgrade the image " \
          "manifest to a newer schema version: https://docs.docker.com/registry/spec/deprecated-schema-v1/"
        else
          stderr
        end
      end

      def invalid_credentials?(stderr)
        stderr.include?('Access denied') ||
          stderr.include?('authentication required') || stderr.include?('incorrect username or password')
      end

      def image_not_found?(stderr)
        stderr.include?('manifest unknown') || stderr.include?('access forbidden')
      end

      def manifest_v1?(stderr)
        stderr.match?(%r{unsupported MediaType.*application/vnd\.docker\.distribution\.manifest\.v1}i)
      end

      def environment
        raise 'Scanner class must implement the `environment` method'
      end

      def db_updated_at
        raise 'Scanner class must implement the `db_updated_at` method'
      end

      def scanner_version
        raise 'Scanner class must implement the `scanner_version` method'
      end

      def scan_command(image_name, output_file_name)
        raise 'Scanner class must implement the `scan_command` method'
      end

      def os_scan_command(image_name, output_file_name)
        raise 'Scanner class must implement the `os_scan_command` method'
      end
    end
  end
end
