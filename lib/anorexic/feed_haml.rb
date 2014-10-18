require 'pathname'
module Anorexic

	# the module FeedHaml implements easy rendering for HAML templates.
	#
	# this is NOT a default module. to use this module use:
	#
	#    require 'anorexic/feed_haml'
	#
	# render a Haml template to a string by calling:
	#    Anorexic::FeedHaml.render :template, layout: :layout_template
	#
	# Templates are searched for in the `app/views` folder.
	#
	module FeedHaml

		module_function

		if defined? Haml
			
			# returns a string representing th rendered Haml template given, after searching for it in the `app/views` folder.
			#
			# for example, to render the file `body.html.haml` with the layout `main_layout.html.haml`:
			#   render :body, layout: :main_layout => "<html><body></body></html>"
			#
			# template:: a Symbol for the template to be used.
			# options:: a Hash for any options such as `:layout` or `locale`.
			#
			# options aceept the following keys:
			# type:: the types for the `:layout' and 'template'. can be any extention, such as `"json"`. defaults to `"html"`.
			# layout:: a layout template that has at least one `yield` statement where the template will be rendered.
			# locals:: a Hash of local variables and their values. i.e. `locals: {a: 1}` .defaults to {}.
			# locale:: the I18n locale for the render.
			# raw:: will pass the content as is, without rendering, to the Haml layout. can be used with :inline. defaults to false.
			# inline:: will render the template inline. requires a String template. defaults to false.
			#
			# if template is a string, it will assume the string is an
			# absolute path to a template file. it will NOT search for the template but might raise exceptions.
			#
			# returns false if the template or layout files cannot be found.
			def render template, options = {}
				# set basics
				options[:locals] ||= {}
				options[:type] ||= "html"
				I18n.locale = options[:locale] if defined?(I18n) && options[:locale]
				# find and open template
				view = nil
				if template.is_a? Symbol
					view = find_template template, options[:type]
				elsif template.is_a? String
					view = template
				end
				return false unless view

				# render using HAML
				if options[:layout]
					# find layout
					if options[:layout].is_a? Symbol
						layout = find_template options[:layout], options[:type]
						return false unless File.exists? layout
						layout = IO.read layout
					elsif options[:layout].is_a? String
						layout = options[:layout] 
					end
					return false unless layout

					# render
					view = render_engine view, options unless options[:raw]
					return false unless view
					return Haml::Engine.new( layout ).render(self, options[:locals]) {  view }
				else
					return render_engine view, options unless options[:raw]
					view
				end
			end

			# an inner method, used by `render` to find the location of the template or layout files.
			#
			# template:: the name of the template (base file name).
			# type:: template type (HTML/XML etc').
			# extention:: template extention (defaulte to: haml).
			def find_template template, type = "", extention = "haml"
				# get all haml files in 'views' folder
				Dir["#{(defined?( Root) ? Root : Pathname.new(Dir.pwd).expand_path).join('app', 'views').to_s}**/**/*.#{extention}"].each do |file|
					return file if file.split(/[\\\/]/).last[0..(0-2-extention.length)].include?(template.to_s + "." + type)
				end
				false
			end

			# an inner method, used by `render` to render the Haml into HTML, using the Haml::Engine and the relevant options.
			#
			# view:: the haml text/file to be rendered (assumes file exists).
			# options:: specific options related to the render mode.
			def render_engine view, options
				return false unless view
				if options[:inline]
					if options[:raw]
						view
					else
						Haml::Engine.new(view).render self, options[:locals]
					end
				else
					if options[:raw]
						IO.read view
					else
						return false unless File.exists? view
						Haml::Engine.new(IO.read view).render self, options[:locals]
					end
				end
			end
		end
	end
end
