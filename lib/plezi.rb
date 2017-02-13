# standard library used by Plezi
require 'json'
require 'erb'
require 'thread'
require 'fileutils'
require 'set'
require 'securerandom'
require 'yaml'

require 'rack'
require 'rack/query_parser.rb'
require 'iodine'

require 'plezi/version'
require 'plezi/api'
require 'plezi/controller/controller'

# Plezi is amazing. Read the {README}
module Plezi
   # Shhh... the modules and classes defined under the {Base} namespace are sleeping...
   #
   # The namespace signifies that Plezi uses these modules and classes internally.
   # We don't need to worry about these unless we're monkey-patching stuff or contributing to the Plezi project.
   module Base
   end
end
