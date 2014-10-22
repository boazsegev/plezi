module Anorexic

	module AnoRack

		#####
		# this class holds the route and matching logic
		# it is used internally and documentation is present for
		# edge users.
		class Route
			# the Regexp that will be used to match the request
			attr_reader :path

			# the initialize method accepts a Regexp or a String and creates the path object.
			#
			# Regexp paths will be left unchanged
			#
			# a string can be either a simple string `"/users"` or a string with paramaters:
			# `"/static/:required/(:optional)/(:optional_with_format){[\d]*}/:optional_2"`
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
							elsif section.match /^\(\:([\w]*)\)\{(.*)\}$/
								#create a optional section catcher
							 	@path << (  "(\/(" +  section.match(/^\(\:([\w]*)\)\{(.*)\}$/)[2] + "))?"  )
							 	# add paramater recognition value
							 	@fill_paramaters[param_num += 1] = section.match(/^\(\:([\w]*)\)\{(.*)\}$/)[1]
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

			# this performs the match and assigns the paramaters, if required.
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
