# frozen_string_literal: true

module Gcs
  class Converter
    SCHEMA_VERSION = "14.0.6"

    def initialize(source, opt = {})
      @source = source
      @opt = opt
      @remediations = Gcs::Remediations::Collection.new
    end

    def convert
      parsed_report = JSON.parse(@source)
      parsed_report['scan']['start_time'] = @opt.fetch(:start_time, '')
      parsed_report['scan']['end_time'] = @opt.fetch(:end_time, '')

      parsed_report['version'] = SCHEMA_VERSION
      parsed_report['scan']['analyzer']['version'] = Gcs::VERSION

      vulns = []

      parsed_report['vulnerabilities']
        .select { |vulnerability| requested_vulnerability_language?(vulnerability.delete('language')) }
        .each do |vulnerability|
          converted_vuln = Vulnerability.new(vulnerability, @opt.fetch(:image_name, nil))
          vulns << converted_vuln
          @remediations.create_remediation(converted_vuln, vulnerability)
        end

      @remediations.unsupported_os_warning unless @remediations.unsupported_operating_systems.empty?

      parsed_report['vulnerabilities'] = vulns.map(&:to_hash)
      parsed_report['remediations'] = @remediations.to_hash

      parsed_report
    end

    private

    def requested_vulnerability_language?(language)
      return true if language.blank?

      !Gcs::Environment.language_specific_scan_disabled?
    end
  end
end
