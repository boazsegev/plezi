module Plezi
  module Base
    module RenderSASS
      module_function

      SASS_OPTIONS = { style: (ENV['SASS_STYLE'] || ((ENV['ENV'] || ENV['RACK_ENV']) == 'production' ? :compressed : :nested)) }.dup

      def call(filename, _context)
        return false unless defined? ::Sass
        return ::Plezi::Renderer.get_cached(filename) if File.extname(filename) == '.map'.freeze
        return unless File.exist?(filename)
        SASS_OPTIONS[:cache_store] ||= Sass::CacheStores::Memory.new
        # REVIEW: mtime and render sass if necessary
        if refresh_sass?(filename)
          eng = Sass::Engine.for_file(filename, SASS_OPTIONS)
          ::Plezi::Renderer.cache_engine filename, eng.dependencies, File.mtime(filename)
          css, map = eng.render_with_sourcemap("#{File.basename(filename, '.*'.freeze)}.map".freeze)
          # ::Plezi::Base::Renderer.cache_engine filename.sub(/\.s[ac]ss$/, '.map'.freeze), map.to_json(css_uri: File.basename(filename, '.*'.freeze))
          ::Plezi::Renderer.cache_engine "#{filename}.css", css
          return css
        end
        ::Plezi::Renderer.get_cached("#{filename}.css")
      end

      def refresh_sass?(sass)
        mt = ::Plezi::Renderer.cached_date(sass)
        return true if mt != File.mtime(sass)
        # return false unless Plezi.allow_cache_update? # no meaningful performance boost.
        ::Plezi::Renderer.get_cached(sass).each { |e| return true if File.exist?(e.options[:filename]) && (File.mtime(e.options[:filename]) > mt) } # fn = File.join( e.options[:load_paths][0].root, e.options[:filename])
        false
      end
    end

    ::Plezi::Renderer.register :scss, ::Plezi::Base::RenderSASS
    ::Plezi::Renderer.register :sass, ::Plezi::Base::RenderSASS
    ::Plezi::Renderer.register :map, ::Plezi::Base::RenderSASS
    end
end
