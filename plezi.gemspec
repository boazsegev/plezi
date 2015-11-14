# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plezi/version'

Gem::Specification.new do |spec|
  spec.name          = "plezi"
  spec.version       = Plezi::VERSION
  spec.authors       = ["Boaz Segev"]
  spec.email         = ['boaz@2be.co.il']
  spec.summary       = %q{Plezi - the easy way to add Websockets, RESTful routing and HTTP streaming serviced to Ruby Web-Apps.}
  spec.description   = %q{Plezi - the easy way to add Websockets, RESTful routing and HTTP streaming serviced to Ruby Web-Apps.}
  spec.homepage      = "http://www.plezi.io/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "iodine", "~> 0.1.14"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.post_install_message = "Thank you for installing Plezi, the native Ruby Framework for real time web-apps."
  # spec.post_install_message = "** Deprecation Warning:\n\nThank you for installing Plezi, the native Ruby Framework for real time web-apps."

end
