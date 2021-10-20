# frozen_string_literal: true
class String; include Term::ANSIColor; end

module Gcs
  class Util
    HEADINGS = ['STATUS', 'CVE SEVERITY', 'PACKAGE NAME', 'PACKAGE VERSION', 'CVE DESCRIPTION'].freeze
    DB_AGE_THRESHOLD_HOURS = 48

    class << self
      def db_outdated?(last_updated)
        hours_since = TimeDifference.between(Time.now, last_updated).in_hours
        Gcs.logger.info("It has been #{hours_since} hours since the vulnerability database was last updated")
        hours_since > DB_AGE_THRESHOLD_HOURS
      end

      def measure_runtime
        start_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        yield
        end_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        { start_time: start_time, end_time: end_time }
      end

      def write_file(name, content, location, allow_list)
        content['vulnerabilities']&.delete_if { |vuln| allow_list&.allowed?(vuln) }
        full_path = location.join(name)
        Gcs.logger.debug("writing results to #{full_path}")
        FileUtils.mkdir_p(full_path.dirname)
        IO.write(full_path, JSON.dump(content))
      end

      def write_table(report, allow_list)
        extract_row = lambda do |vuln|
          cve = vuln.fetch('cve', '')
          severity = vuln.fetch('severity', '')
          package_name = vuln.dig('location', 'dependency', 'package', 'name') || ''
          version = vuln.dig('location', 'dependency', 'version') || ''
          description = vuln.fetch('description', '')

          description = description.scan(/.{1,70}/).join("\n") if description.size > 70
          is_allowed = allow_list&.allowed?(vuln) ? "Approved".green : "Unapproved".red
          [is_allowed, "#{severity} #{cve}", package_name, version, description]
        end

        rows = report.fetch('vulnerabilities', []).map { |x| extract_row.call(x) }

        return if rows.empty?

        table = Terminal::Table.new(headings: HEADINGS, rows: rows, style: { alignment: :center, all_separators: true })

        puts table.render
      end
    end
  end
end
