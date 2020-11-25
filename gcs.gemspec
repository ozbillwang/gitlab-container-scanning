require_relative 'lib/gcs/version'

Gem::Specification.new do |spec|
  spec.name          = "gcs"
  spec.version       = Gcs::VERSION
  spec.authors       = ["Gitlab Protect Team"]
  spec.email         = ["eldemcan@gmail.com"]

  spec.summary       = %q{ Write a short summary, because RubyGems requires one.}
  spec.description   = %q{ Write a longer description or delete this line.}
  spec.homepage      = "https://gitlab.com"
  spec.license       = 'Nonstandard'

  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = " Set to 'http://mygemserver.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.com"
  spec.metadata["changelog_uri"] = "https://gitlab.com"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.add_runtime_dependency 'thor', '~> 1.0', '>= 1.0.1'
  spec.add_runtime_dependency 'zeitwerk', '~> 2.4', '>= 2.4.1'
  spec.add_development_dependency 'byebug', '~> 11.1', '>= 11.1.3'
  spec.add_runtime_dependency 'console', '~> 1.8'
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
