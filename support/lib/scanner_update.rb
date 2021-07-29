# frozen_string_literal: true
class ScannerUpdate
  VERSION_FILE_PATH = 'version/'
  SCANNERS = {
    trivy: {
      uri: 'https://api.github.com/repos/aquasecurity/trivy/releases/latest',
      template: Gcs::Trivy.template_file
    },
    grype: {
      uri: 'https://api.github.com/repos/anchore/grype/releases/latest',
      template: Gcs::Grype.template_file
    }
  }.freeze

  def initialize(scanner)
    @scanner = scanner
  end

  def version_file
    File.join(VERSION_FILE_PATH, "#{@scanner.upcase}_VERSION")
  end

  def current_version
    File.read(version_file).strip
  end

  def versions
    uri = URI(SCANNERS[@scanner.to_sym][:uri])
    res = Net::HTTP.get_response(uri)
    abort("Can't get latest #{@scanner} release from Github") unless res.code == '200'
    res = JSON.parse(res.body) # e.g.  "tag_name": "v0.19.1"
    [res['tag_name'][1..], current_version]
  end

  def check_versions(new, old)
    abort("#{@scanner} version has not changed: #{new}") unless new != old
    abort("#{@scanner} new version format not recognized: #{new}") unless new.match?(/\d+\.\d+\.\d+/)
  end

  def update_scanner
    new_version, current_version = versions
    check_versions(new_version, current_version)

    puts "Version has changed from #{current_version} to #{new_version}"
    branch_name = "update-#{@scanner}-to-#{new_version}-#{Date.today}"
    puts "Creating #{branch_name} branch"

    git('checkout', '-b', branch_name)

    File.truncate(version_file, 0)
    File.write(version_file, new_version)

    new_content = File.read(SCANNERS[@scanner.to_sym][:template])
                      .sub(/.*[\s\S]*\K"version": "#{current_version}"/, "\"version\": \"#{new_version}\"")

    File.open(SCANNERS[@scanner.to_sym][:template], 'w') do |out|
      out << new_content
    end

    git('add', version_file)
    git('add', SCANNERS[@scanner.to_sym][:template])

    git('commit', '-m', "Update #{@scanner} to version #{new_version}\n\nChangelog: changed")
  end
end
