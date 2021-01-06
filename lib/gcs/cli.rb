# frozen_string_literal: true

module Gcs
  class Cli < Thor
    desc 'scan IMAGE', 'Scan a image'
    def scan(image_name = ::Gcs::Environment.default_docker_image)
      stdout, _stderr, status = nil
      measured_time = Gcs::Util.measure_runtime do
        stdout, _stderr, status = Trivy.scan_image(image_name)
      end

      Gcs.logger.info(stdout)

      if status.success?
        if File.exist?(Trivy::DEFAULT_OUTPUT_NAME)
          gitlab_format = Converter.new(File.read(Trivy::DEFAULT_OUTPUT_NAME), nil, measured_time).convert
          Gcs::Util.write_file do
            JSON.dump(gitlab_format)
          end
        end
      else
        Gcs.logger.error(_stderr)
        Gcs.logger.error(stdout)
        Gcs.logger.info('Scan failed please re-run scanner with debug mode to see more details')
        exit 1
      end
    end
  end
end
