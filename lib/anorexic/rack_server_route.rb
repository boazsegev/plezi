module Anorexic

	module AnoRack

		#####
		# this class holds the route and matching logic
		class Route
			# the Regexp 
			attr_reader :path
			def initialize path
				@fill_paramaters = {}
				if path.is_a? Regexp
					@path = path
				elsif path.is_a? String
					if path == '*'
						@path = /.*/
					else
						param_num = 0
						section_search = "(\/[^\/]*)"
						optional_section_search = "(\/[^\/]*)?"
						@path = '^'
						path = path.gsub(/(^\/)|(\/$)/, '').split '/'
						path.each do |section|
							if section == '*'
								# create catch all
								@path << ".*"
								# finish
								@path = /#{@path}$/
								return

							# check for routes formatted: /:paramater - required paramaters
							elsif section.match /^\:([\w]*)$/
								#create a simple section catcher
							 	@path << section_search
							 	# add paramater recognition value
							 	@fill_paramaters[param_num += 1] = section.match(/^\:([\w]*)$/)[1]


							# check for routes formatted: /(:paramater) - optional paramaters
							elsif section.match /^\(\:([\w]*)\)$/
								#create a optional section catcher
							 	@path << optional_section_search
							 	# add paramater recognition value
							 	@fill_paramaters[param_num += 1] = section.match(/^\(\:([\w]*)\)$/)[1]

							# check for routes formatted: /(:paramater){options} - optional paramaters
							elsif section.match /^\(\:([\w]*)\)\{([^\/\{\}]*)}$/
								#create a optional section catcher
							 	@path << (  "(\/(" +  section.match(/^\(\:([\w]*)\)\{([^\/\{\}]*)}$/)[2] + "))?"  )
							 	# add paramater recognition value
							 	@fill_paramaters[param_num += 1] = section.match(/^\(\:([\w]*)\)\{([^\/\{\}]*)}$/)[1]
							 	param_num += 1 # we are using to spaces

							else
								@path << "\/"
								@path << section
							end
						end
						if @fill_paramaters.empty?
							@path << optional_section_search
							@fill_paramaters[param_num += 1] = "id"
						end
						@path = /#{@path}$/
					end
				else
					raise "Path cannot be initialized - path must be either a string or a regular experssion."
				end	
				return
			end
			def match path
				m = @path.match path
				return false unless m
				hash = {}
				@fill_paramaters.each { |k, v|  hash[v] = m[k][1..-1] if m[k] && m[k] != '/' }
				hash
			end
		end



	end
end
