module Rack
	class Request
		def path
			@path ||= script_name + path_info
		end
		def path= new_path
			@path = new_path
		end
		def original_path
			script_name + path_info
		end
	end
end
