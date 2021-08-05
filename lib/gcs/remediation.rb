# frozen_string_literal: true

module Gcs
  class Remediation
    extend Forwardable
    attr_accessor :remediate_metadata, :cve, :id, :fixes, :docker_file

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
      'debian' => 'apt',
      'ubuntu' => 'apt',
      'alpine' => 'apk',
      'photon' => 'tdnf',
      'amazon' => 'yum',
      'centos' => 'yum',
      'oracle' => 'yum',
      'redhat' => 'yum',
      'opensuse' => 'zypper',
      'opensuse.leap' => 'zypper'
    }.freeze

    Fixes = Struct.new(:cve, :id) do
      def ==(other)
        id == other.id
      end

      def hash
        id.hash
      end

      def to_hash
        { 'cve' => cve, 'id' => id }
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
      # Gcs.logger.info("making compare_id from #{remediate_metadata.keys} #{remediate_metadata.values}")
      Digest::SHA1.hexdigest(remediation_formula)
    end

    def add_fix(cve, id)
      fixes.add(Fixes.new(cve, id))
    end

    def ==(other)
      compare_id == other.compare_id
    end

    def hash
      compare_id.hash
    end

    def to_hash
      return {} unless supported_operating_system?

      {
        fixes: fixes.to_a.map(&:to_hash),
        summary: remediate_metadata['summary'],
        diff: create_git_diff
      }
    end

    # updates docker file and creates git diff in Base64 to be used as patch
    def create_git_diff
      write_remediation
      stdout, stderr, status = Gcs.shell.execute(['git diff', docker_file.to_path])

      Gcs.logger.info(stdout)
      return Base64.strict_encode64(stdout.strip) if status.success?

      Gcs.logger.error("Problem generating remediation: #{stderr}")

      ''
    end

    # check if os is unkown till here
    def write_remediation
      IO.write(docker_file.to_path, File.open(docker_file) do |f|
        f.read.gsub(LAST_FROM_KEYWORD_LINE) do |match|
          "#{match}\nRUN #{remediation_formula}"
        end
      end
      )
    end

    def operating_system
      @operating_system ||= remediate_metadata.operating_system.match(/[a-z]*/).to_s
    end

    def supported_operating_system?(os = operating_system)
      PACKAGE_MANAGER_MAPPINGS.include?(os)
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
