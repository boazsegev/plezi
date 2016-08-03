module Plezi
  module Base
    module RenderSASS
      module_function

      SASS_OPTIONS = { style: (ENV['SASS_STYLE'] || ((ENV['ENV'] || ENV['RACK_ENV']) == 'production' ? :compressed : :nested)) }.dup

      def call(filename, _context)
        tmp = nil
        return unless defined? ::Sass
        return (tmp = ::Plezi::Renderer.get_cached(filename)) && tmp[0] if File.extname(filename) == '.map'.freeze
        return unless File.exist?(filename)
        load_engine(filename)
      end

      if ENV['RACK_ENV'.freeze] == 'production'.freeze
        def load_engine(filename)
          engine, tm = ::Plezi::Renderer.get_cached("#{filename}.css")
          return engine if engine
          data = IO.read filename
          data, tm = ::Plezi::Renderer.cache_engine(filename, "<div class='toc'>#{::Plezi::Base::RenderMarkDown::MD_RENDERER_TOC.render(data)}</div>\n#{::Plezi::Base::RenderMarkDown::MD_RENDERER.render(data)}", File.mtime(filename))
          data
        end
      else
        def load_engine(filename)
          engine, tm = ::Plezi::Renderer.get_cached(filename)
          return ::Plezi::Renderer.get_cached("#{filename}.css")[0] if !engine && !refresh_sass?(engine, tm)
          SASS_OPTIONS[:cache_store] ||= Sass::CacheStores::Memory.new
          eng = Sass::Engine.for_file(filename, SASS_OPTIONS)
          tm = File.mtime(filename)
          ::Plezi::Renderer.cache_engine filename, eng.dependencies, tm
          css, map = eng.render_with_sourcemap("#{File.basename(filename, '.*'.freeze)}.map".freeze)
          ::Plezi::Base::Renderer.cache_engine filename.sub(/\.s[ac]ss$/, '.map'.freeze), map.to_json(css_uri: File.basename(filename, '.*'.freeze))
          ::Plezi::Renderer.cache_engine "#{filename}.css", css, tm
        end
    end

      def refresh_sass?(sass, _tm)
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
