module Plezi
  module Base
    module RenderERB
      module_function

      def call(filename, context, &block)
        return unless defined? ::ERB
        return unless File.exist?(filename)
        engine = load_engine(filename)
        engine.result(context, &block)
      end
      if ENV['RACK_ENV'.freeze] == 'production'.freeze
        def load_engine(filename)
          engine = ::Plezi::Renderer.get_cached(filename)
          return engine if engine
          ::Plezi::Renderer.cache_engine(filename, ERB.new(::Plezi.try_utf8!(IO.binread(filename))), File.mtime(filename))
        end
      else
        def load_engine(filename)
          engine = ::Plezi::Renderer.get_cached(filename)
          return engine if engine && ::Plezi::Renderer.cached_date(filename) == File.mtime(filename)
          ::Plezi::Renderer.cache_engine(filename, ERB.new(::Plezi.try_utf8!(IO.binread(filename))), File.mtime(filename))
        end
    end
  end
  end
end

::Plezi::Renderer.register :erb, ::Plezi::Base::RenderERB
