# frozen_string_literal: true

module Gcs
  class Grype < Scanner
    class << self
      def scan_image(image_name, output_file_name)
        cmd = ["grype #{verbosity_flag} registry:#{image_name} -o template -t #{template_file} > #{output_file_name}"]
        Gcs.logger.info(
          <<~HEREDOC
          Scanning container from registry #{Gcs::Environment.default_docker_image} \
          for vulnerabilities with severity level #{Gcs::Environment.severity_level_name} or higher, \
          with gcs #{Gcs::VERSION} and Grype #{version_info}, advisories updated at #{db_updated_at}
          HEREDOC
        )

        Gcs.shell.execute(cmd, environment)
      end

      private

      def version_info
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
          "GRYPE_REGISTRY_INSECURE_SKIP_TLS_VERIFY" => docker_registry_security_config[:docker_insecure].to_s
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
