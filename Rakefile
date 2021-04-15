# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:spec_unit) do |t|
  t.rspec_opts = '--tag ~@integration'
end

RSpec::Core::RakeTask.new(:spec_integration) do |t|
  t.rspec_opts = '--tag integration'
end

task default: :spec
task unit_test: :spec_unit
task integration_test: :spec_integration

# rubocop: disable Rails/RakeEnvironment
task :integration do
  if ENV['CI_SERVER']
    Rake::Task['spec_integration'].invoke
  else
    commands = ["docker build -q -t gcs .",
                "docker run
                  --rm
                  -it
                  --privileged
                  --volume \"$PWD:/home/gitlab/gcs/\"
                  gcs:latest bash -c \"sudo gcs/script/setup_integration; cd gcs; bundle exec rake integration_test\""]
    system(commands.join(';'))
  end
end
# rubocop: enable Rails/RakeEnvironment
