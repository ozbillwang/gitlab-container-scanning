# frozen_string_literal: true

module Gcs
  class Cli < Thor
    OUTPUT_FILE = "tmp.json"

    desc 'scan IMAGE', 'Scan an image'
    def scan(image_name = ::Gcs::Environment.docker_image)
      stdout, stderr, status = nil
      measured_time = Gcs::Util.measure_runtime do
        stdout, stderr, status = Environment.scanner.scan_image(image_name, OUTPUT_FILE)
      end

      Gcs.logger.info(stdout)

      if status.success?
        if File.exist?(OUTPUT_FILE)
          gitlab_format = Converter.new(File.read(OUTPUT_FILE), Environment.docker_file, measured_time).convert
          if File.exist?(Environment.allow_list_file_path)
            allow_list = YAML.load_file(Environment.allow_list_file_path)
            Gcs.logger.info("#{Environment.allow_list_file_path} file found")
          end

          Gcs::Util.write_table(gitlab_format, allow_list)
          Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, gitlab_format, Environment.project_dir, allow_list)
        end
      else
        Gcs.logger.info('Scan failed please re-run scanner with debug mode to see more details')
        Gcs.logger.error(stderr)
        Gcs.logger.error(stdout)
        exit 1
      end
    end
  end
end
