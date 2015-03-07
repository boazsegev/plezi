# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plezi/version'

Gem::Specification.new do |spec|
  spec.name          = "plezi"
  spec.version       = Plezi::VERSION
  spec.authors       = ["Boaz Segev"]
  spec.email         = ['boaz@2be.co.il']
  spec.summary       = %q{The Ruby Web-App Framework with Websockets, REST and HTTP streaming support.}
  spec.description   = %q{Plezi is a Rack free Ruby Web-App Framework with native Websocket, HTTP streaming, and REST routing support. Advance to next step in Ruby evolution - a framework with an integrated server, ready for seamless WebSockets and RESTful applications.}
  spec.homepage      = "http://boazsegev.github.io/plezi/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.post_install_message = "This update might break existing code - please review ChangeLog.md before upgrading any apps.\n\r\n\rFor example\n\r-Please make sure to change any `params[:list]['0'.to_sym][:key]` to `params[:list][0][:key]` (Fixnum rather then String).\n\r- Pleasemake sure to update `params[:check] == 'true'` to `params[:check] == true` (not aString)."

end
