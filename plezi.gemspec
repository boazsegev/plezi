# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plezi/version'

Gem::Specification.new do |spec|
  spec.name          = "plezi"
  spec.version       = Plezi::VERSION
  spec.authors       = ["Boaz Segev"]
  spec.email         = ['boaz@2be.co.il']
  spec.summary       = %q{Plezi is the native Ruby Framework for real time web-apps. An easy way to write Websockets, RESTful routing and HTTP streaming apps.}
  spec.description   = %q{Plezi is the native Ruby Framework for real time web-apps. An easy way to write Websockets, RESTful routing and HTTP streaming apps.}
  spec.homepage      = "http://boazsegev.github.io/plezi/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "grhttp", "~> 0.0.4"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.post_install_message = "Thank you for installing Plezi, the native Ruby Framework for real time web-apps."
  # spec.post_install_message = "** Deprecation Warning:\n- The current code for default error pages will be changed in version 0.9.0.\n- Default error pages will follow a different naming and location conventions.\n- The updated design will be part of the updated `plezi` helper script.\nPlease review your code before upgrading to the 0.9.0 version.\n\nThank you for installing Plezi, the native Ruby Framework for real time web-apps."

end
