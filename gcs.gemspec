# frozen_string_literal: true
require_relative 'lib/gcs/version'

Gem::Specification.new do |spec|
  spec.name          = 'gcs'
  spec.version       = Gcs::VERSION
  spec.authors       = ['Gitlab Protect Team']
  spec.email         = ['gitlab@gitlab.com']

  spec.summary       = %q( Write a short summary, because RubyGems requires one.)
  spec.description   = %q( Write a longer description or delete this line.)
  spec.homepage      = 'https://gitlab.com'
  spec.license       = 'Nonstandard'

  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.4")

  spec.metadata['source_code_uri'] = 'https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning'
  spec.metadata['changelog_uri'] = 'https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/CHANGELOG.md'

  spec.files = Dir.glob("{bin,lib,ee,exe}/**/*")

  spec.add_runtime_dependency 'console', '~> 1.8'
  spec.add_runtime_dependency 'term-ansicolor', '~> 1.7'
  spec.add_runtime_dependency 'terminal-table', '~> 3.0'
  spec.add_runtime_dependency 'thor', '~> 1.0'
  spec.add_runtime_dependency 'zeitwerk', '~> 2.4'

  spec.add_development_dependency 'gitlab-styles', '~> 7.1.0'
  spec.add_development_dependency 'json_schemer', '~> 0.2.18'
  spec.add_development_dependency 'single_cov', '~> 1.6'
  spec.add_development_dependency 'webmock', '~> 3.12'

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib', 'ee/lib']
end
