require 'plezi/version'
require 'iodine'

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

###############
## Dev notes.
###############
#
# Plezi 0.13.0 is heaviliy Rack based. Whenever Possible, Rack middleware was preffered.
# The is a list of available Rack middleware:
# * https://github.com/rack/rack/wiki/List-of-Middleware
#
#
#
#
#
# def uuid
#   @uuid ||= SecureRandom.uuid
# end
# def redis_channel_name
# 		@redis_channel_name ||= "#{File.basename($0, '.*')}_redis_channel"
# end
