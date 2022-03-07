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
          { 'cve' => cve, 'id' => id }
        end
      end

      def_delegators(:@remediate_metadata, :package_name, :package_version, :fixed_version)
      def initialize(remediate_metadata, docker_file)
        @remediate_metadata = Struct.new(*remediate_metadata.keys.map(&:to_sym), keyword_init: true)
                                    .new(remediate_metadata)
        @docker_file = docker_file
        @new_docker_file = Tempfile.new
        @fixes = Set.new
      end

      def compare_id
        Digest::SHA1.hexdigest(remediation_formula)
      end

      def add_fix(cve, id)
        fixes.add(Fixes.new(cve, id))
      end

      def to_hash
        return {} unless supported_operating_system?

        {
          fixes: fixes.to_a.map(&:to_hash),
          summary: remediate_metadata['summary'],
          diff: create_patch
        }
      end

      def supported_operating_system?(os = operating_system)
        PACKAGE_MANAGER_MAPPINGS.include?(os)
      end

      private

      # updates docker file and creates patch in Base64 to be used as patch
      def create_patch
        write_remediation
        stdout, stderr, status = Gcs.shell.execute(
          ['diff -Naur', @docker_file.to_path, @new_docker_file.to_path])

        Gcs.logger.debug(stdout)

        # Exit status is 0 if inputs are the same, 1 if different, 2 if trouble.
        if status.exitstatus >= 2
          Gcs.logger.error("Problem generating remediation: #{stderr}")

          return ''
        end

        diff_to_patch(stdout)
      end

      def diff_to_patch(diff)
        # remove the '--- a ...' '---b ...' lines that `diff -Naur creates`
        patch_lines = diff.strip.split("\n").drop(2)

        # adds the lines expected by `git apply`
        relative_path = @docker_file.relative_path_from(Dir.pwd)
        patch_lines.unshift("+++ b/#{relative_path}")
        patch_lines.unshift("--- a/#{relative_path}")
        patch_lines.unshift("diff --git a/#{relative_path} b/#{relative_path}")

        Base64.strict_encode64(patch_lines.join("\n"))
      end

      def write_remediation
        IO.write(@new_docker_file.to_path, File.open(@docker_file) do |f|
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
