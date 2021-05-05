# frozen_string_literal: true

module Gcs
  class Trivy
    class << self
      def scan_image(image_name, output_file_name)
        trivy_template_file = "@#{File.join(Gcs.lib, 'gitlab.tpl')}"
        cmd = ["trivy i --skip-update --vuln-type os --no-progress --format template -t",
               trivy_template_file,
               "-o",
               output_file_name,
               image_name]
        Gcs.logger.info("Running trivy with: #{cmd.join(' ')}")
        Gcs.shell.execute(cmd)
      end
    end
  end
end
