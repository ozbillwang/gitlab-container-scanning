# frozen_string_literal: true
module Gcs
  class Scanner
    class << self
      def template_file
        File.join(Gcs.lib, 'template', "#{scanner_name.downcase}.tpl").to_s
      end

      def scan_image(image_name, output_file_name)
        disabled_remediation_info unless Gcs::Environment.docker_file.exist?
        Gcs.logger.info(log_message(image_name))
        stdout, stderr, status = Gcs.shell.execute(scan_command(image_name, output_file_name), environment)
        stdout, stderr, status = Gcs.shell.execute(scan_command(image_name, output_file_name), environment)

        [stdout, improve_stderr_msg(stderr, image_name), status]
      end

      private

      def os_scan_command(image_name)
        ["docker run -it --rm -v /home/gitlab/:/home/gitlab #{image_name} /home/gitlab/os-scan"]
      end

      def scanner_name
        name.split('::').last
      end

      def disabled_remediation_info
        Gcs.logger.info(
          <<~EOMSG
          Remediation is disabled; #{Gcs::Environment.docker_file} cannot be found. Have you set `GIT_STRATEGY` and 
          `DOCKERFILE_PATH`?
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
          "The credentials set in DOCKER_USER and DOCKER_PASSWORD are either empty or not valid. " \
          "Please set valid credentials."
        elsif image_not_found?(stderr)
          "The image #{image_name} could not be found. " \
          "To change the image being scanned, use the DOCKER_IMAGE environment variable. " \
          "For details, see https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables"
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
    end
  end
end
