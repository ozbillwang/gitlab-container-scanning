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

task :integration do
  if ENV['CI_SERVER']
    Rake::Task['spec_integration'].invoke
  else
    commands =  ["docker build -q -t gcs .",
    "docker run --rm -it --privileged --volume \"$PWD:/gcs/\" gcs:latest bash -c \"gcs/script/setup_integration; cd gcs; bundle exec rake integration_test\""]
    system(commands.join(';'))
  end
end