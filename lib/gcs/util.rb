# frozen_string_literal: true
module Gcs
  class Util
    class << self
      def measure_runtime
        start_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        yield
        end_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        { start_time: start_time, end_time: end_time }
      end

      def write_file(name = Gcs::DEFAULT_REPORT_NAME, content = nil, location)
        full_path = location.join(name)
        Gcs.logger.debug("writing results to #{full_path}")
        FileUtils.mkdir_p(full_path.dirname)
        IO.write(full_path, block_given? ? yield : content)
      end

      def write_table(report)
        extract_row = lambda do |vuln|
          severity = vuln.fetch('severity', '')
          package_name = vuln.dig('location', 'dependency', 'package', 'name') || ''
          version = vuln.dig('location', 'dependency', 'version') || ''
          description = vuln.fetch('description', '')

          description = description.scan(/.{1,100}/).join("\n") if description.size > 100

          [severity, package_name, version, description]
        end

        rows = report.fetch('vulnerabilities', []).map { |x| extract_row.(x) }

        return if rows.empty?

        table = Terminal::Table.new(headings: ['CVE SEVERITY', 'PACKAGE NAME', 'PACKAGE VERSION', 'CVE DESCRIPTION'], rows: rows)
        puts table.render
      end
    end
  end
end
