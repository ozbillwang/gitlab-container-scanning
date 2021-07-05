# frozen_string_literal: true
module Gcs
  class Shell
    SPLIT_SCRIPT = "'BEGIN {x=0;} /BEGIN CERT/{x++} { print > \"custom.\" x \".crt\" }'"

    DEFAULT_CUSTOM_CERTIFICATE_PATH = '/usr/local/share/ca-certificates/custom.crt'
    DEFAULT_UBI_CUSTOM_CERTIFICATE_PATH = '/etc/pki/ca-trust/source/anchors/custom.crt'

    attr_reader :logger

    def initialize(logger: Gcs.logger, certificate: ENV['ADDITIONAL_CA_CERT_BUNDLE'])
      @logger = logger
      trust!(certificate) if present?(certificate)
    end

    def execute(command, env = {})
      expanded_command = expand(command)
      collapsible_section(expanded_command) do
        logger.debug(expanded_command)
        stdout, stderr, status = Open3.capture3(default_env.merge(env), expanded_command)
        record(stdout, stderr, status)
        [stdout, stderr, status]
      end
    end

    def custom_certificate_installed?
      present?(ENV['ADDITIONAL_CA_CERT_BUNDLE']) && custom_certificate_path.exist?
    end

    private

    def expand(command)
      Array(command).flatten.join(' ')
    end

    def trust!(certificate)
      custom_certificate_path.write(certificate)
      Dir.chdir custom_certificate_path.dirname do
        execute([:awk, SPLIT_SCRIPT, '<', custom_certificate_path])
        Gcs::Environment.ubi? ? execute('update-ca-trust extract') : execute('update-ca-certificates -v')

        Dir.glob('custom.*.crt').each do |path|
          execute([:openssl, :x509, '-in', File.expand_path(path), '-text', '-noout'])
        end
      end

      execute([:cp, custom_certificate_path.to_s, OpenSSL::X509::DEFAULT_CERT_DIR])
      execute([:c_rehash, '-v']) unless Gcs::Environment.ubi?
    end

    def present?(item)
      !item.nil? && !item.empty?
    end

    def record(stdout, stderr, status)
      if status
        logger.debug(stdout)
        logger.debug(stderr)
      else
        logger.error(stderr)
      end
    end

    def collapsible_section(header)
      id = header.downcase.gsub(/[[:space:]]/, '_').gsub(/[^0-9a-z ]/i, '_')
      logger.debug("\nsection_start:#{Time.now.to_i}:#{id}\r\e[0K#{header}")
      yield
    ensure
      logger.debug("\nsection_end:#{Time.now.to_i}:#{id}\r\e[0K")
    end

    def default_env
      { 'SSL_CERT_FILE' => ::Pathname.new(OpenSSL::X509::DEFAULT_CERT_FILE).to_s }
    end

    def custom_certificate_path
      return ::Pathname.new(DEFAULT_UBI_CUSTOM_CERTIFICATE_PATH) if Gcs::Environment.ubi?

      ::Pathname.new(DEFAULT_CUSTOM_CERTIFICATE_PATH)
    end
  end
end
