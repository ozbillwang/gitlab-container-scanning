module Gcs
  class Trivy
    class << self
      def scan_image(image_name)
        cmd = %w(trivy i --vuln-type os --no-progress --format template -t '@./gitlab.tpl' -o tmp.json) << image_name
        Gcs.logger.info("Running trivy with: #{cmd.join(' ')}")
        Gcs.shell.execute(cmd)
      end
    end
  end
end