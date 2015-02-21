# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'anorexic/version'

Gem::Specification.new do |spec|
  spec.name          = "anorexic"
  spec.version       = Anorexic::VERSION
  spec.authors       = ["Boaz Segev"]
  spec.email         = ['boaz@2be.co.il']
  spec.summary       = %q{The Ruby Websocket Framework with RESTful and HTTP streaming support.}
  spec.description   = %q{Anorexic is The Ruby Websocket and HTTP streaming Framework. Advance to next step in Ruby evolution - a framework with an integrated server, ready for seamless WebSockets and RESTful applications.}
  spec.homepage      = "http://boazsegev.github.io/anorexic/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.post_install_message = "Anorexic is hungry - feed it your code!"

end
