# frozen_string_literal: true
module Gcs
  module Plugin
    class DependencyScan
      def scan(image_name, output_file)
        Environment.scanner.scan_os_packages(image_name, output_file)
      end

      def convert(scanner_output, scan_metadata)
        template = File.read(Environment.scanner.dependencies_template_file)
        report = DependencyListConverter.new(template, scanner_output, scan_metadata).convert

        Gcs::Util.write_file(Gcs::DEFAULT_DEPENDENCY_REPORT_NAME, report, Environment.project_dir, nil)
      end

      def handle_failure
        Gcs.logger.error('OS dependency scan failed. Use `SECURE_LOG_LEVEL=debug` to see more details.')
      end

      def enabled?
        !Environment.dependency_scan_disabled? && Environment.scanner.scan_os_packages_supported?
      end

      def skip
        template = File.read(Environment.scanner.dependencies_template_file)
        report = DependencyListConverter.new(template, nil, empty_runtime).convert

        Gcs::Util.write_file(Gcs::DEFAULT_DEPENDENCY_REPORT_NAME, report, Environment.project_dir, nil)

        nil
      end

      private

      def empty_runtime
        time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        { start_time: time, end_time: time }
      end
    end
  end
end
