require 'plezi/router/route'
require 'plezi/router/errors'
require 'plezi/router/assets'

module Plezi
   module Base
      module Router
         class ADClient
            def index
               fname = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'resources', 'client.js'))
               response.body = File.open(fname)
               response['X-Sendfile'] = fname
               true
            end

            def show
               index
            end
         end
      end
   end
end
