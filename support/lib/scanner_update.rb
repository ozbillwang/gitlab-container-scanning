# frozen_string_literal: true
module ScannerUpdate
  TRIVY_VERSION_FILE = './version/TRIVY_VERSION'
  TRIVY_TEMPLATE_FILE = 'lib/gitlab.tpl' # TODO: DRY-up against lib/gcs/trivy.rb:15

  def trivy_versions
    uri = URI("https://api.github.com/repos/aquasecurity/trivy/releases/latest")
    res = Net::HTTP.get_response(uri)
    abort("Can't get latest release from Github") unless res.code == '200'
    res = JSON.parse(res.body) # e.g.  "tag_name": "v0.19.1"
    [res['tag_name'][1..], File.read(TRIVY_VERSION_FILE).strip]
  end

  def check_versions(new, old)
    abort("Version has not changed: #{new}") unless new != old
    abort("New version format not recognized: #{new}") unless new.match?(/\d+\.\d+\.\d+/)
  end

  def update_trivy
    new_version, current_version = trivy_versions
    check_versions(new_version, current_version)

    puts "Version has changed from #{current_version} to #{new_version}"
    branch_name = "update-trivy-to-#{new_version}-#{Date.today}"
    puts "creating #{branch_name} branch"

    git('checkout', '-b', branch_name)

    File.truncate(TRIVY_VERSION_FILE, 0)
    File.write(TRIVY_VERSION_FILE, new_version)

    new_content = File.read(TRIVY_TEMPLATE_FILE)
                      .sub(/.*[\s\S]*\K"version": "#{current_version}"/, "\"version\": \"#{new_version}\"")

    File.open(TRIVY_TEMPLATE_FILE, 'w') do |out|
      out << new_content
    end

    git('add', TRIVY_VERSION_FILE)
    git('add', TRIVY_TEMPLATE_FILE)

    git('commit', '-m', "Update Trivy to version #{new_version}\n\nChangelog: changed")
  end
end
