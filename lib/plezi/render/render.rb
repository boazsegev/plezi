module Plezi
   module Renderer
      @render_library = {}.dup

      public

      module_function

      # Registers a rendering extention.
      #
      # Slim, Markdown, ERB and SASS are registered by default.
      #
      # extention:: a Symbol or String representing the extention of the file to be rendered. i.e. 'slim', 'md', 'erb', etc'
      # handler :: a Proc or other object that answers to call(filename, context, &block) and returnes the rendered string.
      #            The block accepted by the handler is for chaining rendered actions (allowing for `yield` within templates)
      #            and the context is the object within which the rendering should be performed (if `binding` handling is
      #            supported by the engine). `filename` might not point to an existing or valid file.
      #
      # If a block is passed to the `register_hook` method with no handler defined, it will act as the handler.
      def register(extention, handler = nil, &block)
         handler ||= block
         raise 'Handler or block required.' unless handler
         @render_library[extention.to_s] = handler
         handler
      end

      # Removes a registered render extention
      def remove(extention)
         @render_library.delete extention.to_s
      end

      # Attempts to render the requested file (i.e. `'index.html'`) using all known rendering handlers.
      def render(base_filename, context = (Object.new.instance_eval { binding }), &block)
         ret = nil
         @render_library.each { |ext, handler| ret = handler.call("#{base_filename}.#{ext}".freeze, context, &block); return ret if ret; }
         ret
      end
      # Renderer.register :haml do |filename, context, &block|
      #   next unless defined? ::Haml
      #   (Plezi.cache_needs_update?(filename) ? Plezi.cache_data(filename, Haml::Engine.new(Plezi::Base::Helpers.try_utf8!(IO.binread(filename)))) : (Plezi.get_cached filename)).render(context.receiver, &block)
      # end
   end
end

require 'plezi/render/slim.rb'
require 'plezi/render/markdown.rb'
require 'plezi/render/erb.rb'
