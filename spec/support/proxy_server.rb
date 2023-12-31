# frozen_string_literal: true

class ProxyServer
  include Singleton

  DOMAINS = [
    'docker.test'
  ].freeze

  attr_accessor :pid

  def start
    DOMAINS.each { |domain| add_host(domain, '127.0.0.1') }
    FileUtils.mkdir(Gcs.root.join('tmp')) unless Pathname.new(Gcs.root.join('tmp')).exist?

    Dir.chdir Gcs.root.join('tmp') do
      host = 'wildcard.test'
      subject_alternative_names = DOMAINS.map { |x| "DNS:#{x}" }.join(',')
      system([
        "rm -f #{host}.*",
        "/usr/bin/openssl req -x509 -newkey rsa:4096 -keyout #{host}.key -out #{host}.crt -days 999 -nodes" \
        " -subj '/CN=*.test' -addext 'subjectAltName=#{subject_alternative_names}'",
        "cat #{host}.* > #{host}.pem"
      ].join("&&"))
    end
    config_file = Gcs.root.join("spec/fixtures/haproxy.cfg")
    self.pid = spawn("sudo /usr/sbin/haproxy -f #{config_file}")
    wait_for_server
    pid
  end

  def stop(pid = self.pid)
    return unless pid

    system("sudo kill -9 #{pid}")
    Process.wait(pid)

    if Gcs::Environment.ubi?
      system("rm -f /etc/pki/ca-trust/source/anchors/custom.*")
      system("rm -f #{OpenSSL::X509::DEFAULT_CERT_DIR}/custom.*")
      system('update-ca-trust extract')
    else
      system("rm -f /usr/local/share/ca-certificates/custom.*")
      system("rm -f #{OpenSSL::X509::DEFAULT_CERT_DIR}/custom.*")
      system("update-ca-certificates")
      system("c_rehash")
    end
  end

  private

  def add_host(name, ip)
    return if system("grep #{name} /etc/hosts")

    system("echo '#{ip} #{name}' | sudo tee -a /etc/hosts")
  end

  def wait_for_server
    DOMAINS.each do |domain|
      print "." until system("curl -s -k https://#{domain} > /dev/null")
    end
  end
end
