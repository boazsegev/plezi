# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plezi/version'

Gem::Specification.new do |spec|
  spec.name          = 'plezi'
  spec.version       = Plezi::VERSION
  spec.authors       = ['Boaz Segev']
  spec.email         = ['bo@plezi.io']

  spec.summary       = 'The Plezi.io Ruby Framework for real time web applications.'
  spec.description   = 'The Plezi.io Ruby Framework for real time web applications.'
  spec.homepage      = 'http://plezi.io'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'iodine', '~> 0.2', '>= 0.2.7'
  spec.add_dependency 'rack', '>= 2.0.0'
  spec.add_dependency 'bundler', '~> 1.13'
  # spec.add_dependency 'redcarpet', '> 3.3.0'
  # spec.add_dependency 'slim', '> 3.0.0'

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
