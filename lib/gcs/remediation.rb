# frozen_string_literal: true

module Gcs
  class Remediation
    extend Forwardable
    attr_accessor :remediate_metadata, :cve, :id, :fixes, :docker_file

    # LAST_FROM_KEYWORD = /FROM(?![\s\S]+FROM[\s\S]+)/.freeze
    LAST_FROM_KEYWORD_LINE = /.*FROM.*(?![\s\S]+FROM[\s\S]+)/.freeze

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

    def_delegators(:@remediate_metadata, :operating_system, :package_name, :package_version, :fixed_version)
    def initialize(remediate_metadata, docker_file)
      @remediate_metadata = OpenStruct.new(remediate_metadata)
      @docker_file = docker_file
      @fixes = Set.new
    end

    def compare_id
      # Gcs.logger.info("making compare_id from #{remediate_metadata.keys} #{remediate_metadata.values}")
      Digest::SHA1.hexdigest(remediate_metadata.values.join(':'))
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
      {
        fixes: fixes.to_a.map(&:to_hash),
        summary: remediate_metadata.dig('summary'),
        diff: create_git_diff
      }
    end

    # updates docker file and creates git diff in Base64 to be used as patch
    def create_git_diff
      write_remediation
      stdout, _stderr, status = Gcs.shell.execute(['git diff', docker_file.to_path])

      Gcs.logger.info(stdout)
      return Base64.strict_encode64(stdout.strip) if status.success?

      Gcs.logger.error('Problem generating remediation')

      ''
    end

    # check if os is unkown till here
    def write_remediation
      IO.write(docker_file.to_path, File.open(docker_file) do |f|
        f.read.gsub(LAST_FROM_KEYWORD_LINE) do |match|
          "#{match}\n#{remediation_formula}"
        end
      end
    )

    end

    def remediation_formula
      remediation_commands = {
        'debian' => "apt-get update && apt-get upgrade -y #{package_name} && rm -rf /var/lib/apt/lists/*",
        'ubuntu' => "apt-get update && apt-get upgrade -y #{package_name} && rm -rf /var/lib/apt/lists/*",
        'oracle' => "apt-get update && apt-get upgrade -y #{package_name} && rm -rf /var/lib/apt/lists/*",
        'alpine' => "apk --no-cache update && apk --no-cache add #{package_name}=#{fixed_version}",
        'centos' => "yum -y check-update || { rc=$?; [ $rc -neq 100 ] && exit $rc; yum update -y #{package_name}; } && yum clean all"
      }

      remediation_commands[operating_system]
    end
  end
end
