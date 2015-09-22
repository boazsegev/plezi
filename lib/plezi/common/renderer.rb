module Plezi
	module Base

		class ExtentionManager
			def initialize
				@render_library = {}
				@locker = Mutex.new
			end
			# Registers a rendering extention.
			#
			# Slim, Haml and ERB are registered by default.
			#
			# extention:: a Symbol or String representing the extention of the file to be rendered. i.e. 'slim', 'md', 'erb', etc'
			# handler :: a Proc or other object that answers to call(filename, context, &block) and returnes the rendered string. The block accepted by the handler is for chaining rendered actions (allowing for `yield` within templates) and the context is the object within which the rendering should be performed (if `binding` handling is supported by the engine).
			#
			# If a block is passed to the `register_hook` method with no handler defined, it will act as the handler.
			def register extention, handler = nil, &block
				handler ||= block
				raise "Handler or block required." unless handler
				@locker.synchronize { @render_library[extention.to_s] = handler }
				handler
			end
			def review extention
				@locker.synchronize { @render_library[extention.to_s] }
			end
			# Removes a registered render extention
			def remove extention
				@locker.synchronize { @render_library.delete extention.to_s }
			end
			def each &block
				block_given? ? @render_library.each(&block) :  @render_library.each
			end


			def render base_filename, context = self, &block
				@render_library.each {|ext, handler| f = "#{base_filename}.#{ext}".freeze ; return handler.call(f, context, &block) if File.exists?(f) }
				false
			end

		end

		module SASSExt
			module_function

			def call filename, context, &block
				return false unless defined? ::Sass
				@sass_cache ||= Sass::CacheStores::Memory.new if defined?(::Sass)
				# review mtime and render sass if necessary
				if refresh_sass?(filename)
					eng = Sass::Engine.for_file(filename, cache_store: @sass_cache)
					Plezi.cache_data filename, eng.dependencies
					css, map = eng.render_with_sourcemap("#{File.basename(filename, '.*'.freeze)}.map".freeze)
					Plezi.cache_data filename.sub(/\.s[ac]ss$/, '.map'.freeze), map.to_json( css_uri: File.basename(filename, '.*'.freeze) )
					css
				end
			end

			def refresh_sass? sass
				return false unless File.exists?(sass)
				return true if Plezi.cache_needs_update?(sass)
				mt = Plezi.file_mtime(sass)
				Plezi.get_cached(sass).each {|e| return true if File.exists?(e.options[:filename]) && (File.mtime(e.options[:filename]) > mt)} # fn = File.join( e.options[:load_paths][0].root, e.options[:filename]) 
				false
			end
		end
	end

	# asset rendering extentions.
	module AssetManager
		@render_library = {}
		@locker = Mutex.new

		module_function
		# Registers a rendering extention for a specific asset type (js, css, etc').
		#
		# type:: the type of 
		# extention:: a Symbol or String representing the extention of the file to be rendered. i.e. 'scss', 'sass', 'coffee', etc'
		# handler :: a Proc or other object that answers to call(filename, context, &block) and returnes the rendered string. The block accepted by the handler is for chaining rendered actions (allowing for `yield` within templates) and the context is the object within which the rendering should be performed (if `binding` handling is supported by the engine).
		#
		# handlers are expected to manage caching for their data. The {Plezi::Cache} module is available for this task,
		# but it should be noted that Plezi might cache data in that same system and conflicts might occure if the final filename isn't used for the caching (including the handler-type extention, i.e. 'coffee', slim' or 'erb').
		#
		# If a block is passed to the `register_hook` method with no handler defined, it will act as the handler.
		def register type, extention, handler = nil, &block
			raise "Type required." unless type
			handler ||= block
			raise "Handler or block required." unless handler
			@locker.synchronize { (@render_library[type.to_s] ||= ::Plezi::Base::ExtentionManager.new).register extention, handler }
			handler
		end
		# Removes a registered render extention
		def remove type, extention
			@locker.synchronize { (@render_library[type.to_s] ||= ::Plezi::Base::ExtentionManager.new).remove extention.to_s }
		end
		# returns an array with all the registered extentions
		def all_extentions
			out = []
			@render_library.each {|t, l| l.each {|e, h| out << e } }
			out.uniq!
			out
		end


		def render base_filename, context = self, &block
			handler = @render_library[File.extname(base_filename)[1..-1]]
			handler.each {|ext, handler| f = "#{base_filename}.#{ext}".freeze ; return handler.call(f, context, &block) if File.exists?(f) } if handler
			false
		end
	end

	# Render Managment
	Renderer = ::Plezi::Base::ExtentionManager.new

	Renderer.register :erb do |filename, context, &block|
		next unless defined? ::ERB
		( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( ERB.new( IO.binread(filename) ) ) )  : (Plezi.get_cached filename) ).result((context.instance_exec { binding }) , &block)
	end
	Renderer.register :slim do |filename, context, &block|
		next unless defined? ::Slim
		( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( Slim::Template.new() { IO.binread filename } ) )  : (Plezi.get_cached filename) ).render(context, &block)
	end
	Renderer.register :haml do |filename, context, &block|
		next unless defined? ::Haml
		( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, ( Haml::Engine.new( IO.binread(filename) ) ) )  : (Plezi.get_cached filename) ).render(context, &block)
	end

	# JavaScript asset rendering
	AssetManager.register :js, :erb, Renderer.review(:erb)
	AssetManager.register :js, :coffee do |filename, context, &block|
		next unless defined? ::CoffeeScript
		( Plezi.cache_needs_update?(filename) ? Plezi.cache_data( filename, CoffeeScript.compile(IO.binread filename) )  : (Plezi.get_cached filename) )
	end

	# CSS asset rendering
	AssetManager.register :css, :erb, Renderer.review(:erb)
	AssetManager.register :css, :scss, ::Plezi::Base::SASSExt
	AssetManager.register :css, :sass, ::Plezi::Base::SASSExt
end
