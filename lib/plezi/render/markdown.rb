# Redcarpet might not be available, if so, allow the require to throw it's exception.
begin
  require 'redcarpet'

  module Plezi
    module Base
      module RenderMarkDown
        # A custom render engine that makes sure links to foriegn sites open in a new window/tab.
        class NewPageLinksMDRenderer < Redcarpet::Render::HTML
          # review's the link and renders the Html
          def link(link, title, content)
            "<a href=\"#{link}\"#{" target='_blank'" if link =~ /^http[s]?\:\/\//}#{" title=\"#{title}\"" if title}>#{content}</a>"
          end
        end

        # create a single gloabl renderer for all markdown files.
        MD_RENDERER = Redcarpet::Markdown.new NewPageLinksMDRenderer.new(with_toc_data: true), autolink: true, fenced_code_blocks: true, no_intra_emphasis: true, tables: true, footnotes: true

        # create a single gloabl renderer for all markdown TOC.
        MD_RENDERER_TOC = Redcarpet::Markdown.new Redcarpet::Render::HTML_TOC.new

        module_function

        def call(filename, _context)
          return unless defined? ::ERB
          return unless File.exist?(filename)
          load_engine(filename)
        end
        if ENV['RACK_ENV'.freeze] == 'production'.freeze
          def load_engine(filename)
            engine = ::Plezi::Renderer.get_cached(filename)
            return engine if engine
            data = IO.read filename
            data = ::Plezi::Renderer.cache_engine(filename, "<div class='toc'>#{::Plezi::Base::RenderMarkDown::MD_RENDERER_TOC.render(data)}</div>\n#{::Plezi::Base::RenderMarkDown::MD_RENDERER.render(data)}", File.mtime(filename))
            data
          end
        else
          def load_engine(filename)
            engine = ::Plezi::Renderer.get_cached(filename)
            return engine if engine && ::Plezi::Renderer.cached_date(filename) == File.mtime(filename)
            data = IO.read filename
            data = ::Plezi::Renderer.cache_engine(filename, "<div class='toc'>#{::Plezi::Base::RenderMarkDown::MD_RENDERER_TOC.render(data)}</div>\n#{::Plezi::Base::RenderMarkDown::MD_RENDERER.render(data)}", File.mtime(filename))
            data
          end
      end
    end
    end
  end

  ::Plezi::Renderer.register :md, ::Plezi::Base::RenderMarkDown
rescue Exception

end
