# frozen_string_literal: true
module Gcs
  module Plugin
    class SbomScan
      def scan(image_name, output_file)
        Environment.scanner.scan_sbom(image_name, output_file)
      end

      def convert(scanner_output, scan_metadata)
        full_path = Environment.project_dir.join(Gcs::DEFAULT_SBOM_REPORT_NAME)

        Gcs.logger.debug("writing results to sbom #{full_path}")

        FileUtils.mkdir_p(full_path.dirname)

        IO.write(full_path, scanner_output)
      end

      def handle_failure
        Gcs.logger.info('Scan failed. Use `SECURE_LOG_LEVEL=debug` to see more details.')
      end

      def enabled?
        Environment.scanner.scan_sbom_supported?
      end

      def skip
        # no-op
      end
    end
  end
end
