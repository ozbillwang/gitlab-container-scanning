# frozen_string_literal: true

module Gcs
  class Trivy < Scanner
    SEVERITY_LEVELS = {
      "UNKNOWN" => 0,
      "LOW" => 1,
      "MEDIUM" => 2,
      "HIGH" => 3,
      "CRITICAL" => 4
    }.freeze
    UNKNOWN_VERSIONS = { binary_version: 'unknown', db_updated_at: 'unknown' }.freeze

    CACHE_DIR_BASE = "/home/gitlab/.cache/trivy"

    class << self
      def db_updated_at
        version_info[:db_updated_at]
      end

      def scan_os_packages_supported?
        true
      end

      def scan_sbom_supported?
        true
      end

      private

      def scan_command(image_name, output_file_name)
        [
          "echo 10 trivy image",
          "-s HIGH,CRITICAL",
          image_name
        ].compact
      end

      def os_scan_command(image_name, output_file_name)
        [
          "echo 11 trivy image",
          "-s HIGH,CRITICAL",
          image_name
        ]
      end

      def sbom_scan_command(image_name, output_file_name)
        [
          "trivy image",
          "-s HIGH,CRITICAL",
          image_name
        ]
      end

      def version_info
        stdout, _, status = Gcs.shell.execute(%w[trivy --version], environment)

        return UNKNOWN_VERSIONS unless status.success?

        version_info = stdout.split("\n")
        binary_version = version_info.first.chomp
        db_updated_at = DateTime.parse(version_info[3]&.chomp || "").to_s
        { binary_version: binary_version, db_updated_at: db_updated_at }
      rescue Date::Error
        UNKNOWN_VERSIONS
      end

      def severity_level_arg
        return if severity_level.zero?

        allowed_severities = SEVERITY_LEVELS.select { |k, v| v >= severity_level }.keys.join(',')

        "--severity #{allowed_severities}"
      end

      def vulnerability_type_arg
        return unless Gcs::Environment.language_specific_scan_disabled?

        '--vuln-type os'
      end

      def ignore_unfixed_arg
        return unless Gcs::Environment.ignore_unfixed_vulnerabilities?

        '--ignore-unfixed'
      end

      def severity_level
        severity_level_name = Gcs::Environment.severity_level_name
        unless SEVERITY_LEVELS.key?(severity_level_name)
          Gcs.logger.warn('Invalid CS_SEVERITY_THRESHOLD')
          return 0
        end

        SEVERITY_LEVELS[severity_level_name]
      end

      def environment
        docker_registry_credentials = Gcs::Environment.docker_registry_credentials
        docker_registry_security_config = Gcs::Environment.docker_registry_security_config

        {
          "TRIVY_CACHE_DIR" => cache_dir,
          "TRIVY_USERNAME" => docker_registry_credentials && docker_registry_credentials['username'],
          "TRIVY_PASSWORD" => docker_registry_credentials && docker_registry_credentials['password'],
          "TRIVY_DEBUG" => debug_enabled.to_s,
          "TRIVY_INSECURE" => docker_registry_security_config[:docker_insecure].to_s,
          "TRIVY_NON_SSL" => docker_registry_security_config[:registry_insecure].to_s
        }
      end

      def debug_enabled
        true if Gcs::Environment.debug?
      end

      def scanner_version
        version_info[:binary_version]
      end

      def cache_dir
        if Gcs::Environment.ee?
          File.join(CACHE_DIR_BASE, "ee")
        else
          File.join(CACHE_DIR_BASE, "ce")
        end
      end
    end
  end
end
