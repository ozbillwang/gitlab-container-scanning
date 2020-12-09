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
task unit: :spec_unit
task integration: :spec_integration
