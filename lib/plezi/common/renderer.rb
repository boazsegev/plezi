module Plezi
	module Base

		# Render Managment
		module Renderer
			module_function
			# Registers a rendering extention.
			#
			# Slim, Haml and ERB are registered by default.
			#
			# extention:: a Symbol or String representing the extention of the file to be rendered. i.e. 'slim', 'md', 'erb', etc'
			# handler :: a Proc or other object that answers to call(filename, context, &block) and returnes the rendered string. The block accepted by the handler is for chaining rendered actions (allowing for `yield` within templates) and the context is the object within which the rendering should be performed (if `binding` handling is supported by the engine).
			#
			# If a block is passed to the `register_hook` method with no handler defined, it will act as the handler.
			def register_hook extention, handler = nil, &block
				handler ||= block
				raise "Handler or block required." unless handler
				@locker.synchronize { @render_library[extention.to_s] = handler }
				handler
			end
			# Removes a registered render extention
			def remove_hook extention
				@locker.synchronize { @render_library.delete extention.to_s }
			end
			@render_library = {}
			@locker = Mutex.new

			def render base_filename, context = self, &block
				@render_library.each {|ext, handler| f = "#{base_filename}.#{ext}".freeze ; return handler.call(f, context, &block) if File.exists?(f) }
				false
			end

			register_hook :erb do |filename, context, &block|
				next unless defined? ERB
				( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( ERB.new( IO.binread(filename) ) ) )  : (Plezi.get_cached filename) ).result((context.instance_exec { binding }) , &block)
			end
			register_hook :slim do |filename, context, &block|
				next unless defined? Slim
				( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( Slim::Template.new() { IO.binread filename } ) )  : (Plezi.get_cached filename) ).render(context, &block)
			end
			register_hook :haml do |filename, context, &block|
				next unless defined? Haml
				( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( Haml::Engine.new( IO.binread(filename) ) ) )  : (Plezi.get_cached filename) ).render(context, &block)
			end

		end
	end
end
