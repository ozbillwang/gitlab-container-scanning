# frozen_string_literal: true

module Gcs
  class Converter
    attr_accessor :source, :target, :opt

    # @source trivy output
    # @target gcs output
    # opt additional information about scan
    def initialize(source, target, opt = {})
      @source = source
      @target = target
      @opt = opt
    end

    def convert
      parsed_report = JSON.parse(@source)
      parsed_report['scan']['start_time'] = opt.fetch(:start_time, '')
      parsed_report['scan']['end_time'] = opt.fetch(:end_time, '')

      vulns = []
      remediations = {}
      parsed_report['vulnerabilities'].each do |trivy_vuln|
        converted_vuln = Vulnerability.new(trivy_vuln)

        vulns << converted_vuln

        fixed_version = trivy_vuln.dig('remediateMetadata', 'fixedVersion')

        next if fixed_version.nil? || fixed_version.empty?

        rm = Remediation.new(trivy_vuln['remediateMetadata'].merge({ 'operating_system' =>
                                                                       converted_vuln.operating_system }))
        # there is exsiting remedition addressing more than one vulnerability
        if remediations.key?(rm.compare_id)
          remediations[rm.compare_id].add_fix(converted_vuln.cve, converted_vuln.id)
        else
          rm.add_fix(converted_vuln.cve, converted_vuln.id)
          remediations[rm.compare_id] = rm
        end
      end

      parsed_report['vulnerabilities'] = vulns.map(&:to_hash)
      parsed_report['remediations'] = remediations.values.map(&:to_hash)

      parsed_report
    end
  end
end
