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

      Gcs.logger.info(stdout) # FIXME: this prints a blank line on occasion

      if status.success?
        if File.exist?(OUTPUT_FILE)
          gitlab_format = Converter.new(File.read(OUTPUT_FILE), measured_time).convert

          begin
            allow_list = AllowList.new
            Gcs.logger.info("Using allowlist #{AllowList.file_path}")
          rescue StandardError => e
            Gcs.logger.debug("Allowlist failed with #{e.message} for #{AllowList.file_path} ")
          end

          Gcs::Util.write_table(gitlab_format, allow_list) unless ENV['CS_QUIET'] # FIXME: undocumented env var
          Gcs::Util.write_file(Gcs::DEFAULT_REPORT_NAME, gitlab_format, Environment.project_dir, allow_list)
        end
      else
        Gcs.logger.info('Scan failed. Use `SECURE_LOG_LEVEL=debug` to see more details.')
        Gcs.logger.error(stderr)
        Gcs.logger.error(stdout)
        exit 1
      end
    end
  end
end
