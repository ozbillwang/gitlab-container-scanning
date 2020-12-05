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
      parsed_report['vulnerabilities'] = parsed_report['vulnerabilities'].map { |vuln| Vulnerability.new(vuln).to_hash }

      parsed_report
    end
  end
end
