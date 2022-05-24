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

    DATABASE_PATH = "/home/gitlab/.cache/trivy/db"
    DATABASE_FILES = %w[trivy.db metadata.json].freeze

    class << self
      def setup
        DATABASE_FILES.each do |file|
          src = File.join(database_path, file)
          dest = File.join(DATABASE_PATH, file)

          File.delete(dest) if File.exist?(dest)
          File.symlink(src, dest)
        end
      end

      def db_updated_at
        version_info[:db_updated_at]
      end

      def scan_os_packages_supported?
        true
      end

      private

      def scan_command(image_name, output_file_name)
        [
          "trivy image",
          severity_level_arg,
          vulnerability_type_arg,
          ignore_unfixed_arg,
          "--no-progress",
          "--offline-scan --skip-update --security-checks vuln",
          "--format template --template @#{template_file}",
          "--output #{output_file_name}",
          image_name
        ].compact
      end

      def os_scan_command(image_name, output_file_name)
        [
          "trivy image",
          "--list-all-pkgs",
          "--no-progress",
          "--offline-scan --skip-update --security-checks vuln",
          "--format json",
          "--output #{output_file_name}",
          image_name
        ]
      end

      def version_info
        setup

        stdout, _, status = Gcs.shell.execute(%w[trivy --version])

        return "" unless status.success?

        version_info = stdout.split("\n")
        binary_version = version_info.first.chomp
        db_updated_at = DateTime.parse(version_info[4].chomp).to_s
        { binary_version: binary_version, db_updated_at: db_updated_at }
      rescue Date::Error
        { binary_version: 'unknown', db_updated_at: 'unknown' }
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
          "TRIVY_USERNAME" => docker_registry_credentials && docker_registry_credentials['username'],
          "TRIVY_PASSWORD" => docker_registry_credentials && docker_registry_credentials['password'],
          "TRIVY_DEBUG" => debug_enabled.to_s,
          "TRIVY_INSECURE" => docker_registry_security_config[:docker_insecure].to_s,
          "TRIVY_NON_SSL" => docker_registry_security_config[:registry_insecure].to_s
        }
      end

      def debug_enabled
        true if Gcs::Environment.log_level == "debug"
      end

      def scanner_version
        version_info[:binary_version]
      end

      def database_path
        if Gcs::Environment.ee?
          File.join(DATABASE_PATH, "ee")
        else
          File.join(DATABASE_PATH, "ce")
        end
      end
    end
  end
end
