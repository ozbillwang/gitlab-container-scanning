# frozen_string_literal: true

module Gcs
  module Remediations
    class Remediation
      extend Forwardable
      attr_reader :remediate_metadata, :cve, :id, :fixes

      LAST_FROM_KEYWORD_LINE = /.*FROM.*(?![\s\S]+FROM[\s\S]+)/.freeze

      REMEDIATION_COMMANDS = {
        'apt' => "apt-get update && apt-get upgrade -y %{package_name} && rm -rf /var/lib/apt/lists/*",
        'apk' => "apk --no-cache update && apk --no-cache add %{package_name}=%{fixed_version}",
        'tdnf' => "tdnf -y check-update || { rc=$?; [ $rc -neq 100 ] && exit $rc; tdnf update -y %{package_name}; }" \
                  " && tdnf clean all",
        'yum' => "yum -y check-update || { rc=$?; [ $rc -neq 100 ] && exit $rc; yum update -y %{package_name}; }" \
                  " && yum clean all",
        'zypper' => "zypper ref --force && zypper install -y --force %{package_name}=%{fixed_version}"
      }.freeze

      PACKAGE_MANAGER_MAPPINGS = {
        # Both
        'debian' => 'apt',
        'ubuntu' => 'apt',
        'alpine' => 'apk',
        'photon' => 'tdnf',

        # Trivy
        'amazon' => 'yum',
        'centos' => 'yum',
        'opensuse' => 'zypper',
        'oracle' => 'yum',
        'redhat' => 'yum',
        'rocky' => 'yum',
        'alma' => 'yum',
        'opensuse.leap' => 'zypper',

        # Grype
        'amzn' => 'yum',
        'ol' => 'yum',
        'rhel' => 'yum',
        'opensuseleap' => 'zypper'
      }.freeze

      Fixes = Struct.new(:cve, :id) do
        def to_hash
          { 'id' => id }
        end
      end

      def_delegators(:@remediate_metadata, :package_name, :package_version, :fixed_version)
      def initialize(remediate_metadata, docker_file)
        @remediate_metadata = Struct.new(*remediate_metadata.keys.map(&:to_sym), keyword_init: true)
                                    .new(remediate_metadata)
        @docker_file = docker_file
        @fixes = Set.new
      end

      def compare_id
        # rubocop:disable Fips/SHA1
        # https://gitlab.com/gitlab-org/gitlab/-/issues/365171
        OpenSSL::Digest::SHA1.hexdigest(remediation_formula)
        # rubocop:enable Fips/SHA1
      end

      def add_fix(cve, id)
        fixes.add(Fixes.new(cve, id))
      end

      def to_hash
        return {} unless supported_operating_system?

        {
          fixes: fixes.to_a.map(&:to_hash),
          summary: remediate_metadata['summary'],
          diff: create_git_diff
        }
      end

      def supported_operating_system?(os = operating_system)
        PACKAGE_MANAGER_MAPPINGS.include?(os)
      end

      private

      # updates docker file and creates git diff in Base64 to be used as patch
      def create_git_diff
        write_remediation
        stdout, stderr, status = Gcs.shell.execute(['git diff', @docker_file.to_path])

        Gcs.logger.debug(stdout)
        return Base64.strict_encode64(stdout.strip) if status.success?

        Gcs.logger.error("Problem generating remediation: #{stderr}")

        ''
      end

      def write_remediation
        IO.write(@docker_file.to_path, File.open(@docker_file) do |f|
          f.read.gsub(LAST_FROM_KEYWORD_LINE) do |match|
            "#{match}\nRUN #{remediation_formula}"
          end
        end
        )
      end

      def operating_system
        @operating_system ||= remediate_metadata.operating_system.match(/[a-z]*/).to_s
      end

      def package_manager
        PACKAGE_MANAGER_MAPPINGS.fetch(operating_system, "")
      end

      def remediation_formula
        format(
          REMEDIATION_COMMANDS.fetch(package_manager, ""),
          { package_name: package_name, fixed_version: fixed_version }
        )
      end
    end
  end
end
