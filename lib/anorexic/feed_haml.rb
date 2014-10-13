module Anorexic

	# the module FeedHaml holds the main wrapper functions for the I18n and HAML objects.
	#
	# Use I18n by adding `.yml` or `.rb` I18n locales to the `locales` folder in your app.
	#
	# Use HAML by calling (from your rout):
	#    response.body = render :template, type: 'htm', layout: :layout_template
	#
	# Templates are searched for in the `views` folder in your app.
	module FeedHaml

		module_function

		if defined? Haml
			
			# returns a rendered string the HAML template given, after searching for it in the `views` folder.
			#
			# for example, to render the file `body.html.haml` with the layout `main_layout.html.haml`:
			#   render :body, layout: main_layout => "<html><body></body></html>"
			#
			# template:: a Symbol for the template to be used.
			# options:: a Hash for any options such as `:layout` or `locale`.
			#
			# options aceept the following keys:
			# type:: the types for the `:layout' and 'template'. can be any extention, such as `"json"`. defaults to `"html"`.
			# layout:: a layout template that has at least one `yield` statement where the template will be rendered.
			# locals:: a Hash of local variables and their values. i.e. `locals: {a: 1}` .defaults to {}.
			# locale:: the I18n locale for the render.
			# raw:: will pass the content as is, no rendering. can be used with :inline. defaults to false.
			# inline:: will render the template inline. requires a String template. defaults to false.
			#
			# if template is a string, it will assume the string is an
			# absolute path to a template file. it will NOT search for the template but might raise exceptions.
			#
			# it will raise exceptions if the template file cannot be opened or doesn't exist.
			#
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

			def find_template template, type = "", extention = "haml"
				# get all haml files in 'views' folder
				root = Root if defined? Root
				root ||= Pathname.new('.').expand_path
				Dir["#{root.join('app', 'views').to_s}**/**/*.#{extention}"].each do |file|
					return file if file.split(/[\\\/]/).last[0..(0-2-extention.length)].include?(template.to_s + "." + type)
				end
				false
			end

			protected

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
