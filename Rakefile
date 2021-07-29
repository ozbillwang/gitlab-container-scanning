# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'net/http'
require 'pathname'
require 'yaml'
require 'open3'
require 'date'
require 'json'
require 'gcs'
require 'gcs/version'
require_relative 'support/lib/scanner_update'

RSPEC_XML_PATH = ENV['CI_PROJECT_DIR'].to_s == '' ? "rspec.xml" : "#{ENV['CI_PROJECT_DIR']}/rspec.xml"
COMMON_RSPEC_OPTIONS = "--format progress --format RspecJunitFormatter --out #{RSPEC_XML_PATH}"

def git(cmd, *args)
  output, status = Open3.capture2e('git', cmd, *args)

  abort "Failed to run `git #{cmd}`: #{output}" unless status.success?

  output.strip
end

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:spec_unit) do |t|
  t.rspec_opts = "--tag ~@integration #{COMMON_RSPEC_OPTIONS}"
end

RSpec::Core::RakeTask.new(:spec_integration) do |t|
  t.rspec_opts = "--tag integration #{COMMON_RSPEC_OPTIONS}"
end

%w[alpine centos webgoat ca_cert].each do |flag|
  RSpec::Core::RakeTask.new("spec_integration_#{flag}") do |t|
    t.rspec_opts = "--tag integration:#{flag} #{COMMON_RSPEC_OPTIONS}"
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

desc 'Update Trivy binary to latest version'
task :update_trivy do
  ScannerUpdate.new('trivy').update_scanner
end

desc 'Update grype binary to latest version'
task :update_grype do
  ScannerUpdate.new('grype').update_scanner
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

    puts res.body.to_s
    puts "Changelog will be updated" if res.code == "200"
  else
    puts "Env variables are missing project_id: #{ENV['CI_PROJECT_ID']} " \
         "tag: #{ENV['CI_COMMIT_TAG']} token_nil: #{ENV['CS_TOKEN'].nil?}"
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
