# frozen_string_literal: true

module Gcs
  module Remediations
    class Collection
      attr_reader :unsupported_operating_systems, :remediations, :docker_file

      def initialize(docker_file = Gcs::Environment.docker_file)
        @docker_file = docker_file
        @remediations = {}
        @unsupported_operating_systems = Set.new
      end

      def disabled?
        !docker_file.exist?
      end

      def to_hash
        @remediations.values.map(&:to_hash).reject(&:empty?)
      end

      def create_remediation(converted_vuln, vulnerability)
        return if disabled?
        return unless remediation_possible?(vulnerability)
        return unless (new_remediation = remediation(converted_vuln, vulnerability))

        # there is existing remediation addressing more than one vulnerability
        if @remediations.key?(new_remediation.compare_id)
          @remediations[new_remediation.compare_id].add_fix(converted_vuln.cve, converted_vuln.id)
        else
          new_remediation.add_fix(converted_vuln.cve, converted_vuln.id)
          @remediations[new_remediation.compare_id] = new_remediation
        end
      end

      def unsupported_os_warning
        list = @unsupported_operating_systems.to_a.join(",")
        Gcs.logger.warn(
          <<~EOMSG
          This report contained one or more operating systems that are not supported for auto-remediation: #{list}
          The supported distributions can be found at https://docs.gitlab.com/ee/user/application_security/container_scanning/#supported-distributions.
          If you believe this message is incorrect, please file an issue at
          https://gitlab.com/gitlab-org/gitlab/-/issues with the label "Category:Container Scanning"
        EOMSG
        )
      end

      private

      def remediation(converted_vuln, vulnerability)
        os = converted_vuln.operating_system
        new_remediation = Gcs::Remediations::Remediation.new(
          vulnerability['remediateMetadata'].merge({ 'operating_system' => os }), docker_file)

        unless new_remediation.supported_operating_system?
          @unsupported_operating_systems.add(os)
          return nil
        end

        new_remediation
      end

      def remediation_possible?(vulnerability)
        fixed_version = vulnerability.dig('remediateMetadata', 'fixed_version')

        !(fixed_version.nil? || fixed_version.empty?)
      end
    end
  end
end
