module Plezi
	module Base


		# Sends common basic HTTP responses.
		module HTTPSender
			# makes sure to methods are injected to class Class
			class Container
			end
			# the Error Controller, for rendering error templates.
			class ErrorCtrl < Container
				include ::Plezi::Base::ControllerCore
				include ::Plezi::ControllerMagic

				def index
					render(response.status.to_s) || (params[:format] && (params[:format] != 'html'.freeze) && render(response.status.to_s, format: 'html'.freeze)) || ((response['content-type'.freeze] = 'text/plain'.freeze) && response.class::STATUS_CODES[response.status])
				end
				def requested_method
					:index
				end
			end

			module_function

			######
			## basic responses
			## (error codes and static files)

			# sends a response for an error code, rendering the relevent file (if exists).
			def send_by_code request, response, code, headers = {}
				begin
					response.status = code
					headers.each {|k, v| response[k] = v}
					return ErrorCtrl.new(request, response).index
				rescue => e
					Plezi.error e
				end
				false
			end

			# attempts to send a static file by the request path (using `send_file` and `send_raw_data`).
			#
			# returns true if data was sent.
			def send_static_file request, response
				root = request[:host_settings][:public]
				return false unless root
				file_requested = request[:path].to_s.split('/'.freeze)
				unless file_requested.include? '..'.freeze
					file_requested.shift
					file_requested = File.join(root, *file_requested)
					return true if send_file request, response, file_requested
					return send_file request, response, File.join(file_requested, request[:host_settings][:index_file])
				end
				false
			end

			# sends a file/cacheed data if it exists. otherwise returns false.
			def send_file request, response, filename, status_code = 200, headers = {}
				if Plezi.file_exists?(filename) && !::File.directory?(filename)
					data = if Plezi::Cache::CACHABLE.include?(::File.extname(filename)[1..-1])
						Plezi.load_file(filename)
					else
						::File.new filename, 'rb'
					end
					return send_raw_data request, response, data , MimeTypeHelper::MIME_DICTIONARY[::File.extname(filename)], status_code, headers
				end
				return false
			end
			# sends raw data through the connection. always returns true (data send).
			def send_raw_data request, response, data, mime, status_code = 200, headers = {}
				headers.each {|k, v| response[k] = v}
				response.status = status_code if response.status == 200 # avoid resetting a manually set status 
				response['content-type'.freeze] = mime
				response['cache-control'.freeze] ||= 'public, max-age=86400'.freeze				
				response.body = data
				# response['content-length'] = data.bytesize #this one is automated by the server and should be avoided to support Range requests.
				true
			end
		end

	end
end
