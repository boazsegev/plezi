require 'plezi/render/has_cache' unless defined? ::Plezi::Base::HasStore
module Plezi
   module Base
      module RenderERB
         extend ::Plezi::Base::HasStore

         module_function

         def call(filename, context, &block)
            return unless defined? ::ERB
            return unless File.exist?(filename)
            engine = load_engine(filename)
            engine.result(context, &block)
         end
         if ENV['RACK_ENV'.freeze] == 'production'.freeze
            def load_engine(filename)
               engine = self[filename]
               return engine if engine
               self[filename] = ::ERB.new(::Plezi.try_utf8!(IO.binread(filename)))
            end
         else
            def load_engine(filename)
               engine, tm = self[filename]
               return engine if engine && (tm == File.mtime(filename))
               self[filename] = [(engine = ::ERB.new(::Plezi.try_utf8!(IO.binread(filename)))), File.mtime(filename)]
               engine
            end
         end
      end
   end
end

::Plezi::Renderer.register :erb, ::Plezi::Base::RenderERB
