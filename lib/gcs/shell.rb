# frozen_string_literal: true
  module Gcs
    class Shell
      SPLIT_SCRIPT = "'BEGIN {x=0;} /BEGIN CERT/{x++} { print > \"custom.\" x \".crt\" }'"

      attr_reader :default_env, :default_certificate_path, :custom_certificate_path, :logger

      def initialize(logger: Gcs.logger, certificate: ENV['ADDITIONAL_CA_CERT_BUNDLE'])
        @logger = logger
        @custom_certificate_path =  ::Pathname.new('/usr/local/share/ca-certificates/custom.crt')
        @default_certificate_path = ::Pathname.new('/etc/ssl/certs/ca-certificates.crt')
        @default_env = { 'SSL_CERT_FILE' => @default_certificate_path.to_s }
        trust!(certificate) if present?(certificate)
      end

      def execute(command, env: {})
        expanded_command = expand(command)
        collapsible_section(expanded_command) do
          logger.info(expanded_command)
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
          execute('update-ca-certificates -v')

          Dir.glob('custom.*.crt').each do |path|
            execute([:openssl, :x509, '-in', File.expand_path(path), '-text', '-noout'])
          end
        end
        execute([:mkdir, "-p", "/etc/docker/certs.d/docker.test:443/"])
        execute([:cp, custom_certificate_path.to_s, "/etc/docker/certs.d/docker.test:443/ca.crt"])
        execute([:cp, custom_certificate_path.to_s, "/usr/lib/ssl/certs/"])
        execute([:c_rehash, '-v'])
      end

      def present?(item)
        !item.nil? && !item.empty?
      end

      def record(stdout, stderr, status)
        if status
          logger.debug(stdout)
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
    end
  end
