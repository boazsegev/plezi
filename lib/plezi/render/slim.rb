module Plezi
  module Base
    module RenderSlim
      module_function

      def call(filename, context, &block)
        return unless defined? ::Slim
        return unless File.exist?(filename)
        engine = load_engine(filename)
        engine.render(context.receiver, &block)
      end
      if ENV['RACK_ENV'.freeze] == 'production'.freeze
        def load_engine(filename)
          engine = ::Plezi::Renderer.get_cached(filename)
          return engine if engine
          ::Plezi::Renderer.cache_engine(filename, (Slim::Template.new { ::Plezi.try_utf8!(IO.binread(filename)) }), File.mtime(filename))
        end
      else
        def load_engine(filename)
          engine = ::Plezi::Renderer.get_cached(filename)
          return engine if engine && (::Plezi::Renderer.cached_date(filename) == File.mtime(filename))
          ::Plezi::Renderer.cache_engine(filename, (Slim::Template.new { ::Plezi.try_utf8!(IO.binread(filename)) }), File.mtime(filename))
        end
    end
  end
  end
end

::Plezi::Renderer.register :slim, ::Plezi::Base::RenderSlim
