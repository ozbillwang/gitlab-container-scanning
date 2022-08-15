# frozen_string_literal: true
module Gcs
  class Scan
    OUTPUT_FILE = "tmp.json"

    attr_reader :plugin

    def initialize(plugin)
      @plugin = plugin
    end

    def scan_image(image_name)
      return plugin.skip unless plugin.enabled?

      stdout, stderr, status = nil
      options = Gcs::Util.measure_runtime do
        stdout, stderr, status = plugin.scan(image_name, OUTPUT_FILE)
      end.merge(image_name: image_name)

      Gcs.logger.info(stdout)

      if Gcs::Environment.debug?
        if File.exist?(OUTPUT_FILE)
          Gcs.logger.info(File.read(OUTPUT_FILE))
        else
          Gcs.logger.error("Scanner has not created a file with results (#{OUTPUT_FILE})")
        end
      end

      if status&.success? && File.exist?(OUTPUT_FILE)
        scanner_output = File.read(OUTPUT_FILE)
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
