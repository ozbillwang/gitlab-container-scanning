module Gcs
  class Converter

    attr_accessor :source, :target

    def initialize(source, target)
      @source = source
      @target = target
    end

    def convert
      parsed_report = JSON.parse(@source)
      parsed_report['vulnerabilities'].each do |vulnerability|
        vulnerability['message'] = 'temp' if vulnerability['message'] == ''
        image, os = vulnerability.dig('location', 'image').split(' ', 2)
        # vulnerability['location']['operating_system'] = os[1..-2].delete(" \t\r\n")
        # vulnerability['cve'] = "#{vulnerability.dig('location', 'operating_system')}:#{vulnerability.dig('location', 'dependency', 'package', 'name')}:#{vulnerability['cve']}"
        vulnerability['location']['image'] = image
        vulnerability['id'] = Digest::SHA1.hexdigest("#{vulnerability['cve']}:#{vulnerability['location']}")
      end
    end
  end
end