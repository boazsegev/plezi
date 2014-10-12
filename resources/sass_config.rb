# encoding: UTF-8

# add functionality if Sass exists.
if defined? Sass
	require 'sass/plugin/rack'
	Anorexic.default_middleware << [Sass::Plugin::Rack]

	# sets the render style to be compact.
	Sass::Plugin.options[:style] = :compact

	# sets the cache location for caching (caches by default)
	Sass::Plugin.options[:cache_location] = Root.join('tmp', 'sass-cache').to_s
	# sets the location for the saas root folder.
	Sass::Plugin.options[:template_location] = Root.join('assets', 'sass').to_s
	# sets the location for rendered files (for static serving).
	Sass::Plugin.options[:css_location] = Root.join('public', 'assets').to_s

	# on Heroku it is not possible to write the css files to the public folder.
	# in reality, it is better to disable Sass for production and sync rendered files.
	Anorexic.default_middleware.pop if ENV['DYNO'] || ENV['RACK_ENV'] == 'production'
end

if defined? Rack::Coffee
	Anorexic.default_middleware << [Rack::Coffee, root: Root.to_s, urls: ['/assets', '/assets/coffee']]
end
