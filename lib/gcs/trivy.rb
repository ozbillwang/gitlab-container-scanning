# frozen_string_literal: true

module Gcs
  class Trivy
    DEFAULT_OUTPUT_NAME = 'tmp.json'

    class << self
      def scan_image(image_name)
        trivy_template_file = "@#{File.join( Gcs.root, 'gitlab.tpl')}"
        # cmd = ["trivy i --skip-update --vuln-type os --no-progress --format template -t", trivy_template_file, "-o tmp.json", image_name]
        cmd = ["trivy i --vuln-type os --no-progress --format template -t", trivy_template_file, "-o tmp.json", image_name]
        Gcs.logger.info("Running trivy with: #{cmd.join(' ')}")
        Gcs.shell.execute(cmd)
      end
    end
  end
end