# frozen_string_literal: true
class String; include Term::ANSIColor; end

module Gcs
  class Util
    class << self
      def measure_runtime
        start_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        yield
        end_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        { start_time: start_time, end_time: end_time }
      end

      def write_file(name, content, location, allow_list)
        update_allow_list(allow_list)
        content['vulnerabilities']&.delete_if{|vuln| is_allowed?(vuln)}
        full_path = location.join(name)
        Gcs.logger.debug("writing results to #{full_path}")
        FileUtils.mkdir_p(full_path.dirname)
        IO.write(full_path, JSON.dump(content))
      end

      def write_table(report, allow_list)
        update_allow_list(allow_list)
        extract_row = lambda do |vuln|
          cve = vuln.fetch('cve', '')
          severity = vuln.fetch('severity', '')
          package_name = vuln.dig('location', 'dependency', 'package', 'name') || ''
          version = vuln.dig('location', 'dependency', 'version') || ''
          description = vuln.fetch('description', '')

          description = description.scan(/.{1,70}/).join("\n") if description.size > 70
          is_allowed = is_allowed?(vuln) ? "Approved".green : "Unapproved".red
          [is_allowed,"#{severity} #{cve}", package_name, version, description]
        end

        rows = report.fetch('vulnerabilities', []).map { |x| extract_row.(x) }

        return if rows.empty?

        table = Terminal::Table.new(headings: ['STATUS','CVE SEVERITY', 'PACKAGE NAME', 'PACKAGE VERSION', 'CVE DESCRIPTION'], rows: rows, style: {alignment: :center, all_separators: true})
        puts table.render
      end

      def is_allowed?(vuln)
        return false unless @allow_list_cve

        cve = vuln.dig('cve')
        package_name = vuln.dig('location', 'dependency', 'package', 'name')
        docker_image = vuln.dig('location', 'image')&.gsub(/\s\S*/, '')

        return false unless cve && package_name

        included_in_general?(cve, package_name) || included_in_images?(cve, package_name, docker_image)
      end

      def update_allow_list(allow_list)
        @allow_list_cve = {
          general: allow_list&.[]("generalallowlist"),
          images: allow_list&.[]("images")
        }
      end

      private

      def included_in_general?(cve, package_name)
        return false unless @allow_list_cve[:general] && @allow_list_cve[:general][cve]

        @allow_list_cve[:general][cve].include?(package_name)
      end 

      def included_in_images?(cve, package_name, docker_image)
        return false unless @allow_list_cve[:images] && docker_image

        image = @allow_list_cve[:images].keys.find{|key| docker_image.include?(key)}
        !!@allow_list_cve.dig(:images, image, cve)&.include?(package_name)
      end
    end
  end
end
