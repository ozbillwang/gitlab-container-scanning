# frozen_string_literal: true

module Gcs
  class Grype
    class << self
      def scan_image(image_name, output_file_name)
        template_file = File.join(Gcs.lib, 'gitlab.grype.tpl').to_s
        cmd = ["grype #{verbosity_flag} registry:#{image_name} -o template -t #{template_file} > #{output_file_name}"]
        Gcs.logger.info("Running grype with: #{cmd.join(' ')}")
        Gcs.shell.execute(cmd, environment)
      end

      private

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
