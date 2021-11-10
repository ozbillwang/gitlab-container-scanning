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

          return unless perform_os_package_scan?

          scan_os_packages(image_name)
        end
      else
        Gcs.logger.info('Scan failed. Use `SECURE_LOG_LEVEL=debug` to see more details.')
        Gcs.logger.error(stderr)
        Gcs.logger.error(stdout)
        exit 1
      end
    end

    desc 'db-check', 'Check if the vulnerability database is up to date'
    def db_check
      last_updated = Environment.scanner.db_updated_at
      Gcs.logger.info("Vulnerability database was lasted updated at #{last_updated}")

      return unless Gcs::Util.db_outdated?(last_updated)

      Gcs.logger.error("The vulnerability database is outdated")
      exit 1
    end

    private

    def perform_os_package_scan?
      !Environment.dependency_scan_disabled? && Environment.scanner.scan_os_packages_supported?
    end

    def scan_os_packages(image_name = ::Gcs::Environment.docker_image)
      stdout, stderr, status = nil
      measured_time = Gcs::Util.measure_runtime do
        stdout, stderr, status = Environment.scanner.scan_os_packages(image_name, OUTPUT_FILE)
      end

      Gcs.logger.info(stdout)

      if status.success?
        gitlab_format = Converter.new(File.read(OUTPUT_FILE), measured_time).convert

        Gcs::Util.write_file(Gcs::DEFAULT_DEPENDENCY_REPORT_NAME, gitlab_format, Environment.project_dir, nil)
      else
        Gcs.logger.error('OS dependency scan failed. Use `SECURE_LOG_LEVEL=debug` to see more details.')
        Gcs.logger.error(stderr)
        Gcs.logger.error(stdout)
      end
    end
  end
end
