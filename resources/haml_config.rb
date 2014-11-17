# encoding: UTF-8

# adds reder functionality if Haml exists.
#
# the methods are added to the top level, so that they are accessible
# within any controller and within the Haml files themselves.
if defined? Haml


	# set some options
	Haml::Options.defaults[:format] = :html5

	# loads a Haml Engine from the Cache if exists. creates a new Haml Engine if there is no Engine available
	def load_haml template, sub_type = nil, extention = "haml"
		filename = File.join(*template.to_s.split('_')) + (sub_type ? ".#{sub_type}" : '') + ".#{extention}"
		return Anorexic.get_cached filename if Anorexic.cached? filename
		Anorexic.cache_data filename, Haml::Engine.new( IO.read(filename) )
	end

	# returns a string representing the rendered Haml template given, after searching for it in the `app/views` folder.
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
		# find template
		view = nil
		if template.is_a?(Symbol) || ( template.is_a?(String) && !options[:raw] && !options[:inline] )
			begin
				view = load_haml(template, options[:type]).render(self, options[:locals])
			rescue Exception => e
				raise "Cannot find template file #{view}"
			end
		elsif template.is_a?(String)
			view = template
			view = Anorexic.load_file view if options[:raw]
			view = Haml::Engine.new(view).render self, options[:locals] if options[:inline] && !options[:raw]
		end
		return false unless view

		return view unless options[:layout]

		#render layout, if relevant

		# find layout
		if options[:layout].is_a? Symbol
			begin
				layout = load_haml options[:layout], options[:type]
			rescue Exception => e
				raise "Cannot find layout file #{layout}"
			end			
		elsif options[:layout].is_a? String
			layout = Haml::Engine.new( options[:layout] )
		end
		return false unless layout

		# render
		return  layout.render(self, options[:locals]) {  view }
	end
end

# still working on ActiveView stand alone...
# if defined? ActionView
# 	ActionView::Renderer.new(ActionView::LookupContext.new(ActionView::PathSet.new(["views"])))
# end