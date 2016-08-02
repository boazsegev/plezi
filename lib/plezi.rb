require 'plezi/version'
require 'iodine'

require 'plezi/api'
require 'plezi/controller/controller'

# Your code goes here...
module Plezi
  # Your code goes here...
  module Base
    # Your code goes here...
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
