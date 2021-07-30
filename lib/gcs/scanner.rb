# frozen_string_literal: true
module Gcs
  class Scanner
    class << self
      def template_file
        File.join(Gcs.lib, 'template', "#{scanner_name.downcase}.tpl").to_s
      end

      def scan_image(image_name, output_file_name)
        Gcs.logger.info(log_message(image_name))
        Gcs.shell.execute(scan_command(image_name, output_file_name), environment)
      end

      private

      def scanner_name
        name.split('::').last
      end

      def log_message(image_name)
        <<~HEREDOC
            Scanning container from registry #{image_name} \
            for vulnerabilities with severity level #{Gcs::Environment.severity_level_name} or higher, \
            with gcs #{Gcs::VERSION} and #{scanner_name} #{scanner_version}, advisories updated at #{db_updated_at}
        HEREDOC
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