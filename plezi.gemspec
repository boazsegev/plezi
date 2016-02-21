# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plezi/version'

Gem::Specification.new do |spec|
  spec.name          = "plezi"
  spec.version       = Plezi::VERSION
  spec.authors       = ["Boaz Segev"]
  spec.email         = ['boaz@2be.co.il']
  spec.summary       = %q{Plezi - the easy way to add Websockets, RESTful routing and HTTP streaming services to Ruby Web-Apps.}
  spec.description   = %q{Plezi - the easy way to add Websockets, RESTful routing and HTTP streaming services to Ruby Web-Apps.}
  spec.homepage      = "http://www.plezi.io/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", "~> 2.0.0.alpha"
  spec.add_dependency "iodine", "~> 0.2.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  # spec.post_install_message = "Thank you for installing Plezi, the native Ruby Framework for real time web-apps."
  spec.post_install_message = "** Deprecation Warning:\n" +
       "Plezi 0.13.0 and Iodine 0.2.0 introduce MAJOR API changes! It is likely that some of the code for your Plezi 0.12.x application will need to be revised.\n\n" +
       "Thank you for installing Plezi, the native Ruby Framework for real time web-apps."

end
