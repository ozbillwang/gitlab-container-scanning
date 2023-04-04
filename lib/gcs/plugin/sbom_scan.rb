# frozen_string_literal: true
module Gcs
  module Plugin
    class SbomScan
      def scan(image_name, output_file)
        Environment.scanner.scan_sbom(image_name, output_file)
      end

      def convert(scanner_output, _scan_metadata)
        Gcs::Util.write_file(Gcs::DEFAULT_SBOM_REPORT_NAME, scanner_output, Environment.project_dir, nil)
      end

      def handle_failure
        Gcs.logger.info('Scan failed. Use `SECURE_LOG_LEVEL=debug` to see more details.')
      end

      def enabled?
        Environment.scanner.scan_sbom_supported? && Environment.sbom_enabled?
      end

      def skip
        # no-op
      end
    end
  end
end
