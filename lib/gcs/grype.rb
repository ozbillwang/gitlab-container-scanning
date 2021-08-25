# frozen_string_literal: true

module Gcs
  class Grype < Scanner
    class << self
      private

      def scan_command(image_name, output_file_name)
        ["grype #{verbosity_flag} registry:#{image_name} -o template -t #{template_file} > #{output_file_name}"]
      end

      def scanner_version
        stdout, _, status = Gcs.shell.execute(%w[grype version])

        return 'unknown' unless status.success?

        stdout.split("\n")[1].split.join(" ")
      end

      def db_updated_at
        stdout, _, status = Gcs.shell.execute("grype db status")

        return 'unknown' unless status.success?

        Date.parse(stdout.split("\n")[1].chomp).to_s
      rescue Date::Error
        'unknown'
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
        if Gcs::Environment.log_level == "debug"
          "-vv"
        else
          "-v"
        end
      end
    end
  end
end
