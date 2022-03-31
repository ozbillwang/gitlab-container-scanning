# frozen_string_literal: true
module Gcs
  module Plugin
    class ContainerScan
      def scan(image_name, output_file)
        Environment.scanner.scan_image(image_name, output_file)
      end

      def convert(scanner_output, scan_metadata)
        gitlab_format = Converter.new(scanner_output, scan_metadata).convert

        allow_list = build_allow_list
        Gcs::Util.write_table(gitlab_format, allow_list) unless ENV['CS_QUIET'] # FIXME: undocumented env var
        Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, gitlab_format, Environment.project_dir, allow_list)
      end

      def build_allow_list
        return unless Environment.ee?

        begin
          allow_list = ::Gcs::AllowList.new
          Gcs.logger.info("Using allowlist #{AllowList.file_path}")
        rescue StandardError => e
          Gcs.logger.debug("Allowlist failed with #{e.message} for #{AllowList.file_path} ")
        end

        allow_list
      end

      def handle_failure
        Gcs.logger.info('Scan failed. Use `SECURE_LOG_LEVEL=debug` to see more details.')
      end

      def enabled?
        true
      end

      def skip
        # no-op
      end
    end
  end
end
