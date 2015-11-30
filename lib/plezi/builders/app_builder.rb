require 'plezi/builders/builder'
module Plezi

	module Base

		class AppBuilder
			def initialize
				@end_comments = []
				@app_tree ||= {}
				@root = ::Plezi::Base::Builder::GEM_ROOT
			end
			def app_tree
				@app_tree ||= {}
			end
			def build_mini app_name = ARGV[1]
				require 'plezi/version'
				app_tree["#{app_name}"] ||= IO.read( File.join(@root, "resources" ,"mini_exec.rb")).gsub('appname', app_name)
				app_tree["#{app_name}.rb"] ||= IO.read( File.join(@root, "resources" ,"mini_app.rb")).gsub('appname', app_name).gsub('appsecret', "#{app_name}_#{SecureRandom.hex}")
				app_tree["Procfile"] ||= String.new
				app_tree["Procfile"] << "\nweb: bundle exec ruby ./#{app_name} -p $PORT\n"		
				app_tree["Gemfile"] ||= String.new
				app_tree["Gemfile"] << "source 'https://rubygems.org'\n\n####################\n# core gems\n\n# include the basic plezi framework and server\ngem 'plezi', '~> #{Plezi::VERSION}'\n"
				app_tree["Gemfile"] << "\n\n\nruby '#{RUBY_VERSION}'\n"
				app_tree["rakefile"] ||= IO.read(File.join(@root,"resources" ,"rakefile")).sub('initialize.rb', "#{app_name}.rb")
				app_tree["templates"] ||= {}
				app_tree["templates"]["404.html.erb"] ||= IO.read(File.join(@root, "resources" ,"404.erb"))
				app_tree["templates"]["500.html.erb"] ||= IO.read(File.join(@root, "resources" ,"500.erb"))
				app_tree["templates"]["welcome.html.erb"] ||= IO.read(File.join(@root, "resources" ,"mini_welcome_page.html")).gsub('appname', app_name)
				app_tree["assets"] ||= {}
				app_tree["assets"]["websocket.js"] ||= IO.read(File.join(@root, "resources" ,"websockets.js")).gsub('appname', app_name)
				finalize app_name
			end

			def build app_name = ARGV[1]
				require 'plezi/version'
				# plezi run script
				app_tree["#{app_name}"] ||= IO.read File.join(@root,"resources" ,"code.rb")

				# set up application files
				app_tree["app"] ||= {}
				app_tree["app"]["controllers"] ||= {}
				app_tree["app"]["controllers"]["sample_controller.rb"] ||= IO.read(File.join(@root,"resources" ,"controller.rb"))
				app_tree["app"]["models"] ||= {}
				app_tree["app"]["views"] ||= {}

				# set up templates for status error codes
				app_tree["app"]["views"]["404.html"] ||= IO.read(File.join(@root,"resources" ,"404.html"))
				app_tree["app"]["views"]["500.html"] ||= IO.read(File.join(@root,"resources" ,"500.html"))
				app_tree["app"]["views"]["404.html.erb"] ||= IO.read(File.join(@root,"resources" ,"404.erb"))
				app_tree["app"]["views"]["500.html.erb"] ||= IO.read(File.join(@root,"resources" ,"500.erb"))
				app_tree["app"]["views"]["404.html.slim"] ||= IO.read(File.join(@root,"resources" ,"404.slim"))
				app_tree["app"]["views"]["500.html.slim"] ||= IO.read(File.join(@root,"resources" ,"500.slim"))
				app_tree["app"]["views"]["404.html.haml"] ||= IO.read(File.join(@root,"resources" ,"404.haml"))
				app_tree["app"]["views"]["500.html.haml"] ||= IO.read(File.join(@root,"resources" ,"500.haml"))

				# set up the assets folder
				app_tree["assets"] ||= {}
				app_tree["assets"]["stylesheets"] ||= {}
				app_tree["assets"]["javascripts"] ||= {}
				app_tree["assets"]["javascripts"]["websocket.js"] ||= IO.read(File.join(@root,"resources" ,"websockets.js")).gsub('appname', app_name)
				app_tree["assets"]["javascripts"]["plezi_client.js"] ||= IO.read(File.join(@root,"resources" ,"plezi_client.js")).gsub('appname', app_name)
				app_tree["assets"]["welcome.html"] ||= IO.read(File.join(@root,"resources" ,"welcome_page.html")).gsub('appname', app_name)

				# app core files.
				app_tree["initialize.rb"] ||= IO.read File.join(@root,"resources" ,"initialize.rb").gsub('appname', app_name)
				app_tree["routes.rb"] ||= IO.read File.join(@root,"resources" ,"routes.rb")
				app_tree["rakefile"] ||= IO.read File.join(@root,"resources" ,"rakefile")
				app_tree["Procfile"] ||= ""
				app_tree["Procfile"] << "\nweb: bundle exec ruby ./#{app_name} -p $PORT\n"
				app_tree["Gemfile"] ||= ''
				app_tree["Gemfile"] << "source 'https://rubygems.org'\n\n####################\n# core gems\n\n# include the basic plezi framework and server\ngem 'plezi', '~> #{Plezi::VERSION}'\n"
				app_tree["Gemfile"] << IO.read( File.join(@root,"resources" ,"Gemfile"))
				app_tree["Gemfile"] << "\n\n\nruby '#{RUBY_VERSION}'\n"

				# set up config files
				app_tree["initialize"] ||= {}
				app_tree["initialize"]["oauth.rb"] ||= IO.read(File.join(@root,"resources" ,"oauth_config.rb"))
				app_tree["initialize"]["active_record.rb"] ||= IO.read(File.join(@root,"resources" ,"db_ac_config.rb"))
				app_tree["initialize"]["sequel.rb"] ||= IO.read(File.join(@root,"resources" ,"db_sequel_config.rb"))
				app_tree["initialize"]["datamapper.rb"] ||= IO.read(File.join(@root,"resources" ,"db_dm_config.rb"))
				app_tree["initialize"]["haml.rb"] ||= IO.read(File.join(@root,"resources" ,"haml_config.rb"))
				app_tree["initialize"]["slim.rb"] ||= IO.read(File.join(@root,"resources" ,"slim_config.rb"))
				app_tree["initialize"]["i18n.rb"] ||= IO.read(File.join(@root,"resources" ,"i18n_config.rb"))
				app_tree["initialize"]["redis.rb"] ||= (IO.read(File.join(@root,"resources" ,"redis_config.rb"))).gsub('appsecret', "#{app_name}_#{SecureRandom.hex}")

				#set up database stub folders
				app_tree["db"] ||= {}
				app_tree["db"]["migrate"] ||= {}
				app_tree["db"]["fixtures"] ||= {}
				app_tree["db"]["config.yml"] ||= IO.read(File.join(@root,"resources" ,"database.yml"))

				#set up the extras folder, to be filled with future goodies.
				# app_tree["extras"] ||= {}
				# app_tree["extras"]["config.ru"] ||= IO.read File.join(@root,"resources" ,"config.ru")

				#set up I18n stub
				app_tree["locales"] ||= {}
				app_tree["locales"]["en.yml"] ||= IO.read File.join(@root,"resources" ,"en.yml")

				# create library, log and tmp folders
				app_tree["logs"] ||= {}
				app_tree["lib"] ||= {}
				app_tree["tmp"] ||= {}


				# set up a public folder for static file service
				app_tree["public"] ||= {}		
				app_tree["public"]["assets"] ||= {}		
				app_tree["public"]["assets"]["stylesheets"] ||= {}		
				app_tree["public"]["assets"]["javascripts"] ||= {}		
				app_tree["public"]["images"] ||= {}
				finalize app_name
			end
			def finalize app_name = ARGV[1]
				begin
					Dir.mkdir app_name
					puts "created the #{app_name} application directory.".green
				rescue => e
					puts "the #{app_name} application directory exists - trying to rebuild (no overwrite).".pink
				end
				Dir.chdir app_name
				puts "starting to write template data...".red
				puts ""
				Builder.write_files app_tree
				File.chmod 0775, "#{app_name}" rescue true
				puts "done."
				puts "\n#{@end_comments.join("\n")}" unless @end_comments.empty?
				puts ""
				puts "please change directory into the app directory: cd #{app_name}"
				puts ""
				puts "run the #{app_name} app using: ./#{app_name} or using: plezi s"
				puts ""
			end
		end
	end
end
