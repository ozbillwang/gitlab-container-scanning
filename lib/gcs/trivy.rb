# frozen_string_literal: true

module Gcs
  class Trivy
    SEVERITY_LEVELS = {
      "UNKNOWN" => 0,
      "LOW" => 1,
      "MEDIUM" => 2,
      "HIGH" => 3,
      "CRITICAL" => 4
    }.freeze

    class << self
      def scan_image(image_name, output_file_name)
        trivy_template_file = "@#{File.join(Gcs.lib, 'gitlab.tpl')}"
        cmd = ["trivy i #{severity_level_arg} --skip-update --vuln-type os --no-progress --format template -t",
               trivy_template_file,
               "-o",
               output_file_name,
               image_name]

        Gcs.logger.info("Trivy version: #{trivy_version}")
        Gcs.logger.info("Running with: #{cmd.join(' ')}")
        Gcs.shell.execute(cmd)
      end

      private

      def trivy_version
        stdout, _, status = Gcs.shell.execute(["trivy", "--version"])

        return "" unless status.success?

        stdout.split("\n").first.chomp
      end

      def severity_level_arg
        return '' if Gcs::Environment.severity_level.zero?

        allowed_severities = SEVERITY_LEVELS.select { |k, v| v >= Gcs::Environment.severity_level }.keys.join(',')

        "-s #{allowed_severities}"
      end
    end
  end
end
