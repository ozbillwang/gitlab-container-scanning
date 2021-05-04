# frozen_string_literal: true

module Gcs
  class Cli < Thor
    desc 'scan IMAGE', 'Scan a image'
    def scan(image_name = ::Gcs::Environment.default_docker_image)
      stdout, stderr, status = nil
      measured_time = Gcs::Util.measure_runtime do
        stdout, stderr, status = Trivy.scan_image(image_name)
      end

      Gcs.logger.info(stdout)

      if status.success?
        if File.exist?(Trivy::DEFAULT_OUTPUT_NAME)
          gitlab_format = Converter.new(File.read(Trivy::DEFAULT_OUTPUT_NAME),
                                        Environment.docker_file, measured_time).convert

          if File.exist?(Environment.allow_list_file_path)
            allow_list = YAML.load_file(Environment.allow_list_file_path)
            Gcs.logger.info("#{Environment.allow_list_file_path} file found")
          end

          Gcs::Util.write_table(gitlab_format, allow_list)
          Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, gitlab_format, Environment.project_dir, allow_list)
        end
      else
        # rubocop: disable Rails/Exit
        Gcs.logger.info('Scan failed please re-run scanner with debug mode to see more details')
        Gcs.logger.error(stderr)
        Gcs.logger.error(stdout)
        exit 1
        # rubocop: enable Rails/Exit
      end
    end
  end
end
