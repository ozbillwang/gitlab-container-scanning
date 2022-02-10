# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'pathname'
require 'yaml'
require 'date'
require 'gcs'
require 'gcs/version'
require_relative 'support/lib/git_helper'
require_relative 'support/lib/gitlab_client'
require_relative 'support/lib/scanner_update'
require_relative 'support/lib/tag_release'

RSPEC_XML_PATH = ENV['CI_PROJECT_DIR'].to_s == '' ? "rspec.xml" : "#{ENV['CI_PROJECT_DIR']}/rspec.xml"
COMMON_RSPEC_OPTIONS = "--format progress --format RspecJunitFormatter --out #{RSPEC_XML_PATH}"

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:spec_unit) do |t|
  t.rspec_opts = "--tag ~@integration #{COMMON_RSPEC_OPTIONS}"
end

RSpec::Core::RakeTask.new(:spec_integration) do |t|
  t.rspec_opts = "--tag integration #{COMMON_RSPEC_OPTIONS}"
end

%w[alpine centos webgoat distroless ca_cert].each do |flag|
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

desc 'Tag a new release'
task :tag_release, :ref do |t, args|
  include TagRelease
  args.with_defaults(ref: "HEAD")
  ref = args[:ref]

  abort "Current branch is not the default branch. Please run `git checkout #{DEFAULT_BRANCH_NAME}`" \
    unless default_branch?

  abort 'Local branch is not up-to-date with remote. Please run `git pull`.' unless git('pull', '--dry-run').empty?

  prev = previous_version
  if prev == Gcs::VERSION
    abort "No version changes detected.\n" \
      'Please update ./lib/gcs/version.rb to the version number that you would like to release.'
  end

  puts "You are about to release version: #{Gcs::VERSION}"
  puts "The previous release version was: #{prev}"
  puts 'If this version number is incorrect, please update ./lib/gcs/version.rb'
  prompt!

  puts 'The following commits will be released. Please verify that they are correct and have changelog trailers.'
  puts '----- BEGIN COMMIT LOG -----'
  puts git('log', "#{prev}..#{ref}")
  puts '----- END COMMIT LOG -----'
  puts 'If there are missing changelogs, please manually add them to CHANGELOG.md post-release'
  prompt!

  puts "Tagging #{ref} with #{Gcs::VERSION} and pushing to remote"
  puts git('tag', Gcs::VERSION, ref)
  puts git('push', 'origin', Gcs::VERSION)

  puts 'Release pipeline should be running at https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/pipelines?scope=tags&page=1'
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
  tag = ENV['CI_COMMIT_TAG']
  if GitlabClient.ci.configured? && tag
    result = GitlabClient.ci.generate_changelog(tag)
    puts "Status: #{result[:code]}"
    puts result[:message]
    puts "Changelog will be updated" if result[:status] == :success
  else
    puts "Env variables are missing project_id: #{ENV['CI_PROJECT_ID']} " \
         "tag: #{tag} token_nil: #{ENV['CS_TOKEN'].nil?}"
  end
end

desc 'Triggers api for rebuilding last tag for updating vulnerability db'
task :trigger_db_update do
  if ENV['TRIGGER_DB_UPDATE'] && ENV['CI_PIPELINE_SOURCE'] == "schedule" && GitlabClient.ci.configured?
    latest_release_tag = GitlabClient.ci.latest_release

    abort 'Could not fetch latest release tag' unless latest_release_tag

    result = GitlabClient.ci.trigger_pipeline(latest_release_tag)

    abort result[:message] if result[:status] != :success

    result[:message]
  end
end
