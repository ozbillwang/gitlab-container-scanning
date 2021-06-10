# frozen_string_literal: true

module Gcs
  class Trivy
    SEVERITY_LEVELS = {
      "UNKNOWN" => 0,
      "LOW" => 1,
      "MEDIUM" => 2,
      "HIGH" => 3,
      "CRITICAL" => 4
    }.freeze

    class << self
      def scan_image(image_name, output_file_name)
        trivy_template_file = "@#{File.join(Gcs.lib, 'gitlab.tpl')}"
        cmd = ["trivy i #{severity_level_arg} --skip-update --vuln-type os --no-progress --format template -t",
               trivy_template_file,
               "-o",
               output_file_name,
               image_name]

        Gcs.logger.debug(cmd.join(' '))
        Gcs.logger.info(
          <<~HEREDOC
          Scanning container from registry #{Gcs::Environment.default_docker_image} \
          for vulnerabilities with severity level #{Gcs::Environment.severity_level_name} or higher, \
          with gcs #{Gcs::VERSION} and Trivy #{version_info[:binary_version]}, advisories updated at #{version_info[:db_updated_at]}
          HEREDOC
        )
        Gcs.shell.execute(cmd, environment)
      end

      private

      def version_info
        stdout, _, status = Gcs.shell.execute(["trivy", "--version"])

        return "" unless status.success?

        version_info = stdout.split("\n")
        binary_version = version_info.first.chomp
        db_updated_at = Date.parse(version_info[4].chomp).to_s
        { binary_version: binary_version, db_updated_at: db_updated_at }
      rescue Date::Error
        { binary_version: 'unknown', db_updated_at: 'unknown' }
      end

      def severity_level_arg
        return '' if Gcs::Environment.severity_level.zero?

        allowed_severities = SEVERITY_LEVELS.select { |k, v| v >= Gcs::Environment.severity_level }.keys.join(',')

        "-s #{allowed_severities}"
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
    end
  end
end
