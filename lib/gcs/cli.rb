# frozen_string_literal: true

module Gcs
  class Cli < Thor
    desc 'scan IMAGE', 'Scan an image'
    def scan(image_name = ::Gcs::Environment.docker_image)
      Gcs::Environment.scanner.setup

      plugins = [
        Gcs::Plugin::ContainerScan,
        Gcs::Plugin::DependencyScan
      ]

      results = plugins.map do |plugin|
        Gcs::Scan.new(plugin).scan_image(image_name)
      end

      return if results.all? do |result|
        next true if result.nil? # Skipped

        result.success?
      end

      exit 1
    end

    desc 'db-check', 'Check if the vulnerability database is up to date'
    def db_check
      Gcs::Environment.scanner.setup

      last_updated = Environment.scanner.db_updated_at
      Gcs.logger.info("Vulnerability database was lasted updated at #{last_updated}")

      return unless Gcs::Util.db_outdated?(last_updated)

      Gcs.logger.error("The vulnerability database is outdated")
      exit 1
    end
  end
end
