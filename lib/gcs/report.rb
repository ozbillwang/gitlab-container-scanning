module Gcs
    class Report
      VERSION = '3.0'

    #   attr_acccessor :vulnerabilities

      def initialize(vulnerabilities)
        @vulnerabilities = vulnerabilities
      end

      def add_vulnerability(params)
        @vulnerabilities << Vulnerability.new(params)
      end

      def vulnerabilities
        @vulnerabilities.map { |v| v.to_hash }
      end

      def to_hash
        {
          version: VERSION,
          vulnerabilities:
        #   remediations: remediations,
        #   scan: scan,
        }
      end

    end
end