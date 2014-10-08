# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'anorexic/version'

Gem::Specification.new do |spec|
  spec.name          = "anorexic"
  spec.version       = Anorexic::VERSION
  spec.authors       = ["Boaz Segev (Myst)"]
  spec.email         = ["boaz@2be.co.il"]
  spec.summary       = %q{ A pure ruby framework for web services - so small, it's anotexic! }
  spec.description   = %q{this is a small and barebones application that allows multi-port, multi-threaded services. It's so small, it's anorexic!

this is a very simple DSL framework for web services (web apps).
<br/>
it defaults to WEBRick, but it will eat Thin, or any suppoted Rack server with the anorexic-thin-mvc gem.

if you want more (HAML, SASS, etc'), it's very easy to add it in... but it's not there!

look for the plugins you want in the ruby community.}
  spec.homepage      = "https://github.com/boazsegev/anorexic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
