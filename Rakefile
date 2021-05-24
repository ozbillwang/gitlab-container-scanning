# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'net/http'
require 'pathname'
require 'yaml'
require 'open3'
require 'date'
require 'json'
require 'gcs/version'

TRIVY_VERSION_FILE = './version/TRIVY_VERSION'

def git(cmd, *args)
  output, status = Open3.capture2e('git', cmd, *args)

  unless status.success?
    abort "Failed to run `git #{cmd}`: #{output}"
  end

  output.strip
end

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:spec_unit) do |t|
  t.rspec_opts = '--tag ~@integration'
end

RSpec::Core::RakeTask.new(:spec_integration) do |t|
  t.rspec_opts = '--tag integration'
end

%w[alpine centos webgoat ca_cert].each do |flag|
  RSpec::Core::RakeTask.new("spec_integration_#{flag}") do |t|
    t.rspec_opts = "--tag integration:#{flag}"
  end
end

task default: :spec
task unit_test: :spec_unit
task integration_test: :spec_integration

task :integration do
  if ENV['CI_SERVER']
    Rake::Task['spec_integration'].invoke
  else
    commands = ["docker build -q -t gcs .",
                "docker run \
                  --rm \
                  -it \
                  --privileged \
                  --volume \"$PWD:/home/gitlab/gcs/\" \
                  gcs:latest bash -c \"sudo gcs/script/setup_integration; cd gcs; bundle;" \
                    "bundle exec rake integration_test\""]
    system(commands.join(';'))
  end
end

desc 'Checks if commit message complies with the format for generating automatic CHANGELOG.md'
task :commit_message do
  exp = /Changelog: (added|fixed|changed|deprecated|removed|security|performance|other)/im
  regex_check = lambda do |content|
    unless content.match?(exp)
      puts "\e[31m!!!Commit message is not correct for auto generating changelog!!!\e[0m"
      abort "\e[31m Please include Changelog: (Added or Changed|Deprecated|Removed|Fixed|Security) commit body \e[0m"
    end
  end

  if ENV['CI'] && ENV['CI_COMMIT_MESSAGE'] && (ENV['CI_COMMIT_BRANCH'] != ENV['CI_DEFAULT_BRANCH'])
    regex_check.call(ENV['CI_COMMIT_MESSAGE'])
  else
    return unless Pathname('.git/COMMIT_EDITMSG').exist?

    content = File.read('.git/COMMIT_EDITMSG')
    regex_check.call(content)
  end
end

desc 'Update Trivy binary to latest version'
task :update_trivy do
  uri = URI("https://api.github.com/repos/aquasecurity/trivy/releases/latest")
  res = Net::HTTP.get_response(uri)
  if res.code == '200'
    res = JSON.parse(res.body)
    current_trivy_version = File.read(TRIVY_VERSION_FILE).strip
    if res['tag_name'] != current_trivy_version
      version = res['tag_name'][1..]
      puts "Version has changed from #{current_trivy_version} to #{version}"
      branch_name = "update-trivy-to-#{version}-#{Date.today}"
      puts "creating #{branch_name} branch"

      if ENV['CI']
        puts "Configuring git for bot user"
        git('config', "--global", "user.email", "csbot@gitlab.com")
        git('config', "--global", "user.name", "CS bot Bot")
        git('config', "--global", "credential.username", "project_#{ENV['CI_PROJECT_ID']}_bot")
      end

      git('checkout', '-b', branch_name, 'master')
      File.truncate(TRIVY_VERSION_FILE, 0)
      File.write(TRIVY_VERSION_FILE, version)
      git('add', TRIVY_VERSION_FILE)
      git('commit', '-m', "Update Trivy version #{Date.today}\nChangelog: changed")
      if ENV['CI']
       remote_git = "https://project_#{ENV['CI_PROJECT_ID']}_bot:#{ENV['CS_TOKEN']}@#{ENV['CI_SERVER_HOST']}/#{ENV['CI_PROJECT_PATH']}.git"
       git('push',
        "-o","merge_request.create",
        "-o", "merge_request.remove_source_branch",
        "-o", "merge_request.label=devops::protect",
        "-o", "merge_request.title=Upgrade trivy to #{version}",
        "-o" ,"merge_request.target=#{ENV['CI_DEFAULT_BRANCH']}", remote_git, branch_name)
      end
    end
  else
    puts "Can't get latest release from Github"
  end
end

desc 'Creates CHANGELOG.md through Gitlab Api'
task :changelog do
  if ENV['CS_TOKEN'] && ENV['CI_PROJECT_ID'] && ENV['CI_COMMIT_TAG']
    uri = URI("https://gitlab.com/api/v4/projects/#{ENV['CI_PROJECT_ID']}/repository/changelog")
    req = Net::HTTP::Post.new(uri)
    req['PRIVATE-TOKEN'] = ENV['CS_TOKEN']
    req['Content-Type'] = 'application/json'
    req.set_form_data(version: ENV['CI_COMMIT_TAG'])
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    puts "#{res.body}"
    puts "Changelog will be updated" if res.code == "200"
  else
    puts "Env variables are missing  project_id: #{ENV['CI_PROJECT_ID']} tag: #{ENV['CI_COMMIT_TAG']} token_nil: #{ENV['CS_TOKEN'].nil?}"
  end
end

desc 'Triggers api for rebuilding last tag for updating vulnerability db'
task :trigger_db_update do
  base_url = "https://gitlab.com/api/v4/projects/#{ENV['CI_PROJECT_ID']}"

  if ENV['TRIGGER_DB_UPDATE'] && ENV['CI_PIPELINE_SOURCE'] == "schedule"
    uri = URI("#{base_url}/releases")
    res = Net::HTTP.get_response(uri)

    if res.code == '200'
      latest_release_tag = JSON.parse(res.body).first['tag_name']
      puts "Triggering a build for #{latest_release_tag}"
      uri = URI("#{base_url}/pipeline?ref=#{latest_release_tag}")
      req = Net::HTTP::Post.new(uri)
      req['PRIVATE-TOKEN'] = ENV['CS_TOKEN']
      req['Content-Type'] = 'application/json'

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      if res.code.start_with?("20")
        res.body
      else
        abort res.body
      end
    else
      abort "Failed to retrieve latest release tag"
    end
  end
end
