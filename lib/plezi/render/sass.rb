require 'plezi/render/has_cache'
# Redcarpet might not be available, if so, allow the require to throw it's exception.
unless defined?(::Sass)
   begin
      require('sass')
   rescue Exception

   end
end

if defined?(::Sass)

   module Plezi
      module Base
         # This is a baker, not a renderer
         module BakeSASS
            extend HasCache

            module_function

            SASS_OPTIONS = { cache_store: Sass::CacheStores::Memory.new, style: (ENV['SASS_STYLE'] || ((ENV['ENV'] || ENV['RACK_ENV']) == 'production' ? :compressed : :nested)) }.dup

            # Bakes the SASS for the requested target, if a SASS source file is found.
            def call(target)
               return self[target] if File.extname(target) == '.map'.freeze
               review_cache("#{target}.scss", target) || review_cache("#{target}.sass", target)
            end

            def review_cache(filename, target)
               return nil unless File.exist?(filename)
               eng = self[filename]
               return true unless eng.nil? || refresh_sass?(filename)
               self[filename] = (eng = Sass::Engine.for_file(filename, SASS_OPTIONS)).dependencies
               map_name = "#{target}.map".freeze
               css, map = eng.render_with_sourcemap(File.basename(map_name))
               self[filename.to_sym] = Time.now
               IO.write map_name, map.to_json(css_uri: File.basename(target))
               self[target] = css
            end

            def refresh_sass?(sass)
               mt = self[sass.to_sym]
               return true if mt < File.mtime(sass)
               self[sass].each { |e| return true if File.exist?(e.options[:filename]) && (File.mtime(e.options[:filename]) > mt) }
               false
            end
         end

         ::Plezi::AssetBaker.register :css, ::Plezi::Base::BakeSASS
         ::Plezi::AssetBaker.register :map, ::Plezi::Base::BakeSASS
      end
   end

end
