require 'singleton'
require 'pathname'
require 'logger'
require 'socket'
require 'openssl'
require 'strscan'
require 'base64'
require 'digest/sha1'
require 'time'
require 'json'

### version

require "anorexic/version"


### Server requirements

require "anorexic/server/services/basic_service"
require "anorexic/server/services/ssl_service"

require "anorexic/server/protocols/http"
require 'anorexic/server/protocols/http_request'
require 'anorexic/server/protocols/http_response'

require "anorexic/server/handlers/http_echo"
require "anorexic/server/handlers/http_host"
require "anorexic/server/handlers/http_router"

require "anorexic/server/helpers/http"
require "anorexic/server/helpers/mime_types"

require "anorexic/server/protocols/websocket"
require 'anorexic/server/protocols/ws_response'

## Server-Framework Bridges
require "anorexic/framework/controller_magic"
require "anorexic/framework/magic_helpers"
require "anorexic/framework/route"


### Framework requirements
require "anorexic/framework/stubs"
require "anorexic/framework/anorexic_methods"

### DSL requirements
require "anorexic/framework/dsl"



##############################################################################
# To make something new, we leap to the unknown.
##############################################################################
module Anorexic
end
