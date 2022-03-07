# frozen_string_literal: true
module Gcs
  class Scan
    OUTPUT_FILE = "tmp.json"

    attr_reader :plugin

    def initialize(plugin)
      @plugin = plugin.new
    end

    def scan_image(image_name)
      return plugin.skip unless plugin.enabled?

      stdout, stderr, status = nil
      measured_time = Gcs::Util.measure_runtime do
        stdout, stderr, status = plugin.scan(image_name, OUTPUT_FILE)
      end

      Gcs.logger.info(stdout) # FIXME: this prints a blank line on occasion

      if status.success? && File.exist?(OUTPUT_FILE)
        scanner_output = File.read(OUTPUT_FILE)
        options = measured_time.merge(image_name: image_name)
        plugin.convert(scanner_output, options)
      else
        plugin.handle_failure
        Gcs.logger.error(stderr)
        Gcs.logger.error(stdout)
      end

      status
    end
  end
end
