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

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  # spec.post_install_message = "Thank you for installing Plezi, the native Ruby Framework for real time web-apps."
  spec.post_install_message = "** Deprecation Warning:\n
  V.0.10.0 will be a major revision. It will also change the Websocket API so that it conforms to the Javascript API, making it clearer.

Also, V. 0.10.0 will utilize the GReactor IO reactor and the GRHttp HTTP and Websocket server gems. Both are native Ruby, so no C or Java extentions should be introduced.

This means that asynchronous tasking will now be handled by GReactor's API.

Make sure to test your app before upgrading to the 0.10.0 version.

Thank you for installing Plezi, the native Ruby Framework for real time web-apps."

end
