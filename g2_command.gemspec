# frozen_string_literal: true

require_relative 'lib/command/version'

Gem::Specification.new do |spec|
  spec.name          = 'g2_command'
  spec.version       = Command::VERSION
  spec.authors       = ['Hamed Asghari']
  spec.email         = ['hasghari@g2.com']

  spec.summary       = 'An implementation of the command pattern using dry-rb'
  spec.homepage      = 'https://github.com/g2crowd/g2_command'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/g2crowd/g2_command'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel', '>= 5.0'
  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'dry-initializer', '~> 3.0'
  spec.add_dependency 'dry-monads', '~> 1.3'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
