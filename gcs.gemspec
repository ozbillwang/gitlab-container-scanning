require_relative 'lib/gcs/version'

Gem::Specification.new do |spec|
  spec.name          = 'gcs'
  spec.version       = Gcs::VERSION
  spec.authors       = ['Gitlab Protect Team']
  spec.email         = ['gitlab@gitlab.com']

  spec.summary       = %q{ Write a short summary, because RubyGems requires one.}
  spec.description   = %q{ Write a longer description or delete this line.}
  spec.homepage      = 'https://gitlab.com'
  spec.license       = 'Nonstandard'

  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = " Set to 'http://mygemserver.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://gitlab.com'
  spec.metadata['changelog_uri'] = 'https://gitlab.com'

  spec.files = Dir.glob("{bin,lib,exe}/**/*")

  spec.add_runtime_dependency 'thor', '~> 1.0'
  spec.add_runtime_dependency 'zeitwerk', '~> 2.4'
  spec.add_runtime_dependency 'console', '~> 1.8'
  spec.add_development_dependency 'single_cov', '~> 1.6'
  spec.add_development_dependency 'json-schema', '~> 2.8'
  spec.add_development_dependency 'dry-schema', '~> 1.5'
  # spec.add_development_dependency 'byebug', '~> 11.1', '>= 11.1.3'
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
