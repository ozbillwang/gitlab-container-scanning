# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'net/http'
require 'pathname'

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
      puts "\e[31m Please include Changelog: (Added or Changed|Deprecated|Removed|Fixed|Security) commit body \e[0m"

      exit 1
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

desc 'Creates CHANGELOG.md through Gitlab Api'
task :changelog do
  if ENV['GITLAB_TOKEN'] && ENV['CI_PROJECT_ID'] && ENV['CI_COMMIT_TAG']
    uri = URI("https://gitlab.com/api/v4/projects/#{ENV['CI_PROJECT_ID']}/repository/changelog")
    req = Net::HTTP::Post.new(uri)
    req['PRIVATE-TOKEN'] = ENV['GITLAB_TOKEN']
    req['Content-Type'] = 'application/json'
    req.set_form_data(version: ENV['CI_COMMIT_TAG'])
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    puts "Changelog will be updated" if res.code == "200"
  else
    puts "Env variables are missing  project_id: #{ENV['CI_PROJECT_ID']} tag: #{ENV['CI_COMMIT_TAG']} token_nil: #{ENV['GITLAB_TOKEN'].nil?}"
  end
end
