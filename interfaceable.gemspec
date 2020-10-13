# frozen_string_literal: true

require_relative 'lib/interfaceable/version'

Gem::Specification.new do |spec|
  spec.name          = 'interfaceable'
  spec.version       = Interfaceable::VERSION
  spec.authors       = ['artemave']
  spec.email         = ['artemave@gmail.com']

  spec.summary       = 'Strict interfaces in Ruby'
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = 'https://github.com/featurist/interfaceable'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/artemave/interfaceable.git'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
