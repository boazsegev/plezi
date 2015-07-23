# encoding: UTF-8

if defined?(Slim)
	require 'rouge/plugins/redcarpet' if defined?(Redcarpet) && defined?(Rouge)
	if defined?(Redcarpet::Render::HTML) && defined?(Rouge::Plugins::Redcarpet)
		Slim::Embedded.options[:markdown] = {
			fenced_code_blocks: true,
			renderer: (Class.new(Redcarpet::Render::HTML) {include Rouge::Plugins::Redcarpet} ).new
		}
	end
end
