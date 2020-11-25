module Gcs
  class Cli < Thor

    desc 'scan LOCKFILE', 'Scan a lockfile and list dependencies/licenses'
    def scan
      stdout, _stderr, status = Trivy.scan_image('alpine:latest')


      # TODO add log level variable
      # Gcs.logger.debug(stdout) if status.success?

      if status.success?
        if File.exist?('tmp.json')
          gitlab_format = Converter.new(File.read('tmp.json'), nil).convert
          write_file do
           JSON.dump(gitlab_format)
          end
        end
      else
        Gcs.logger.error("Scan failed please re-run scanner with debug mode to see more details")
        exit 1
      end
    end

    private

    def write_file(name = 'gl-container-scanning-report.json', content = nil)
      full_path = Pathname.pwd.join(name)
      FileUtils.mkdir_p(full_path.dirname)
      IO.write(full_path, block_given? ? yield : content)
    end
  end
end