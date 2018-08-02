require 'plezi/render/has_cache'
# Redcarpet might not be available, if so, allow the require to throw it's exception.
unless defined?(::SassC)
   begin
      require('sassc')
   rescue Exception

   end
end

if defined?(::SassC)

   module Plezi
      module Base
         # This is a baker, not a renderer
         module BakeSASS
            extend HasCache

            SCSSC_OPTIONS = { filename: :filename, source_map_file: ((ENV['ENV'] || ENV['RACK_ENV']) == 'production' ? false : true), source_map_embed: ((ENV['ENV'] || ENV['RACK_ENV']) == 'production' ? false : true), load_paths: :load_paths, style: (ENV['SASS_STYLE'] || ((ENV['ENV'] || ENV['RACK_ENV']) == 'production' ? :compressed : :nested)) }.dup

            module_function

            # Bakes the SASS for the requested target, if a SASS source file is found.
            def call(target)
               return self[target] if File.extname(target) == '.map'.freeze
               load_target("#{target}.scss", target) || load_target("#{target}.sass", target)
            end

            def load_target(filename, target)
               return nil unless File.exist?(filename)
               eng = self[filename]
               return self[target] unless eng.nil?  || refresh_sass?(filename)
               map_name = "#{target}.map".freeze
               opt = SCSSC_OPTIONS.dup
               opt[:source_map_file] = map_name if opt[:source_map_file]
               opt[:filename] = filename
               opt[:load_paths] = [ File.basename(target) ]
               data = IO.binread(filename)
               eng = SassC::Engine.new(data, opt)
               css = eng.render
               map = eng.source_map
               self[filename] = eng.dependencies
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
