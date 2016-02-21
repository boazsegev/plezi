
module Plezi
  module Base
    # this handles Plezi routing
    module Router
      # makes sure to methods are injected to class Class
			class Container
			end
			# the Error Controller, for rendering error templates.
			class ErrorCtrl < Container
				include ::Plezi::Base::ControllerCore
				include ::Plezi::ControllerMagic

				def index
					render(response.status.to_s) ||
						(params[:format] && (params[:format] != 'html'.freeze) && (params[:format] = 'html'.freeze) && (response['content-type'] = nil).nil? && render(response.status.to_s)) ||
						((response['content-type'.freeze] = 'text/plain'.freeze) && ::Rack::Utils::HTTP_STATUS_CODES[response.status])
				end
				def requested_method
					:index
				end
			end
    end
  end
end
