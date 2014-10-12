# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'anorexic/version'

Gem::Specification.new do |spec|
  spec.name          = "anorexic"
  spec.version       = Anorexic::VERSION
  spec.authors       = ["Boaz Segev (Myst)"]
  spec.email         = ["boaz@2be.co.il"]
  spec.summary       = %q{ A small, pure Ruby, web app DSL/framework... so small - it's anorexic! }
  spec.description   = %q{this is a small and barebones framework that allows easy set up for multi-threaded web services. It's the small alternative to the heavier Rails and Sinatra - It's so small, it's anorexic!}
  spec.homepage      = "https://github.com/boazsegev/anorexic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_runtime_dependency 'rack', '>= 1.5.2'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
