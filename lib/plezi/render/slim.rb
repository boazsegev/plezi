require 'plezi/render/has_cache' unless defined? ::Plezi::Base::HasStore
module Plezi
   module Base
      module RenderSlim
         extend ::Plezi::Base::HasStore

         module_function

         def call(filename, context, &block)
            return unless defined? ::Slim
            return unless File.exist?(filename)
            engine = load_engine(filename)
            engine.render(context.receiver, &block)
         end
         if ENV['RACK_ENV'.freeze] == 'production'.freeze
            def load_engine(filename)
               engine = self[filename]
               return engine if engine
               self[filename] = (Slim::Template.new { ::Plezi.try_utf8!(IO.binread(filename)) })
            end
         else
            def load_engine(filename)
               engine, tm = self[filename]
               return engine if engine && (tm == File.mtime(filename))
               self[filename] = [(engine = Slim::Template.new { ::Plezi.try_utf8!(IO.binread(filename)) }), File.mtime(filename)]
               engine
            end
         end
      end
   end
end

::Plezi::Renderer.register :slim, ::Plezi::Base::RenderSlim
