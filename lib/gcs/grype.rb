# frozen_string_literal: true

module Gcs
  class Grype < Scanner
    class << self
      def db_updated_at
        stdout, _, status = Gcs.shell.execute("grype db status")

        return 'unknown' unless status.success?

        DateTime.parse(stdout.split("\n")[1].chomp).to_s
      rescue Date::Error
        'unknown'
      end

      private

      def scan_command(image_name, output_file_name)
        [
          "grype registry:#{image_name}",
          verbosity_flag,
          only_fixed_flag,
          "--output template --template #{template_file}",
          "> #{output_file_name}"
        ].compact
      end

      def scanner_version
        stdout, _, status = Gcs.shell.execute(%w[grype version])

        return 'unknown' unless status.success?

        stdout.split("\n")[1].split.join(" ")
      end

      def environment
        docker_registry_credentials = Gcs::Environment.docker_registry_credentials
        docker_registry_security_config = Gcs::Environment.docker_registry_security_config

        {
          "GRYPE_DB_AUTO_UPDATE" => false.to_s,
          "GRYPE_CHECK_FOR_APP_UPDATE" => false.to_s,
          "GRYPE_REGISTRY_AUTH_USERNAME" => docker_registry_credentials && docker_registry_credentials['username'],
          "GRYPE_REGISTRY_AUTH_PASSWORD" => docker_registry_credentials && docker_registry_credentials['password'],
          "GRYPE_REGISTRY_INSECURE_SKIP_TLS_VERIFY" => docker_registry_security_config[:docker_insecure].to_s,
          "GRYPE_REGISTRY_INSECURE_USE_HTTP" => docker_registry_security_config[:registry_insecure].to_s
        }
      end

      def verbosity_flag
        if Gcs::Environment.debug?
          "-vv"
        else
          "-v"
        end
      end

      def only_fixed_flag
        return unless Gcs::Environment.ignore_unfixed_vulnerabilities?

        '--only-fixed'
      end
    end
  end
end
