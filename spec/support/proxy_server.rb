# frozen_string_literal: true

class ProxyServer
  include Singleton

  DOMAINS = [
    'custom.docker'
  ].freeze

  attr_accessor :pid

  def start
    puts "=======STARTING SERVER ========="
    DOMAINS.each { |domain| add_host(domain, '127.0.0.1') }
    Dir.chdir Gcs.root.join('tmp') do
      host = 'wildcard.test'
      subject_alternative_names = DOMAINS.map { |x| "DNS:#{x}" }.join(',')
      puts "/usr/bin/openssl req -x509 -newkey rsa:4096 -keyout #{host}.key -out #{host}.crt -days 999 -nodes -subj '/C=/ST=/L=/O=/OU=/CN=*.test' -addext 'subjectAltName=#{subject_alternative_names}'"
      system([
        "rm -f #{host}.*",
        "/usr/bin/openssl req -x509 -newkey rsa:4096 -keyout #{host}.key -out #{host}.crt -days 999 -nodes -subj '/C=/ST=/L=/O=/OU=/CN=*.test' -addext 'subjectAltName=#{subject_alternative_names}'",
        "cat #{host}.* > #{host}.pem"
      ].join("&&"))
    end
    config_file = Gcs.root.join("spec/fixtures/haproxy.cfg")
    puts "config_file #{config_file}"
    self.pid = spawn("/usr/sbin/haproxy -f #{config_file}")
    wait_for_server
    pid
  end

  def stop(pid = self.pid)
    return unless pid

    Process.kill("TERM", pid)
    Process.wait(pid)
    system("rm -f /usr/local/share/ca-certificates/custom.*")
    system("rm -f /usr/lib/ssl/certs/custom.*")
    system("update-ca-certificates -v")
    system("c_rehash -v")
    system("/opt/asdf/installs/mono/6.8.0.123/bin/cert-sync /etc/ssl/certs/ca-certificates.crt")
  end

  private

  def add_host(name, ip)
    return if system("grep #{name} /etc/hosts")

    system("echo '#{ip} #{name}' >> /etc/hosts")
  end

  def wait_for_server
    DOMAINS.each do |domain|
      puts "Warming up #{domain}..."
      print "." until system("curl -s -k https://#{domain} > /dev/null")
      puts "#{domain} is ready!"
    end
  end
end
