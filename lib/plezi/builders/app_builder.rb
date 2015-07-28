module Plezi


	class AppBuilder

		def initialize
			@end_comments = []
			@app_tree ||= {}
		end
		def app_tree
			@app_tree ||= {}
		end
		def build_mini
			require 'plezi/version'
			@app_tree["#{ARGV[1]}"] ||= IO.read( ::File.expand_path(File.join("..", "..", "resources" ,"mini_exec.rb"),  __FILE__)).gsub('appname', ARGV[1])
			@app_tree["#{ARGV[1]}.rb"] ||= IO.read( ::File.expand_path(File.join("..", "..", "resources" ,"mini_app.rb"),  __FILE__)).gsub('appname', ARGV[1]).gsub('appsecret', "#{ARGV[1]}_#{SecureRandom.hex}")
			app_tree["Procfile"] ||= ""
			app_tree["Procfile"] << "\nweb: bundle exec ruby ./#{ARGV[1]} -p $PORT\n"		
			app_tree["Gemfile"] ||= ''
			app_tree["Gemfile"] << "source 'https://rubygems.org'\n\n####################\n# core gems\n\n# include the basic plezi framework and server\ngem 'plezi', '~> #{Plezi::VERSION}'\n"
			app_tree["Gemfile"] << "\n\n\nruby '#{RUBY_VERSION}'\n"
			app_tree["templates"] ||= {}
			app_tree["templates"]["404.html.erb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"404.erb"),  __FILE__))
			app_tree["templates"]["500.html.erb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"500.erb"),  __FILE__))
			app_tree["templates"]["welcome.html.erb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"mini_welcome_page.html"),  __FILE__)).gsub('appname', ARGV[1])
			app_tree["assets"] ||= {}
			app_tree["assets"]["websocket.js"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"websockets.js"),  __FILE__)).gsub('appname', ARGV[1])
			finalize
		end

		def build
			require 'plezi/version'
			# plezi run script
			@app_tree["#{ARGV[1]}"] ||= IO.read ::File.expand_path(File.join("..", "..", "resources" ,"code.rb"),  __FILE__)

			# set up application files
			app_tree["app"] ||= {}
			app_tree["app"]["controllers"] ||= {}
			app_tree["app"]["controllers"]["sample_controller.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"controller.rb"),  __FILE__))
			app_tree["app"]["models"] ||= {}
			app_tree["app"]["views"] ||= {}

			# set up templates for status error codes
			app_tree["app"]["views"]["404.html"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"404.html"),  __FILE__))
			app_tree["app"]["views"]["500.html"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"500.html"),  __FILE__))
			app_tree["app"]["views"]["404.html.erb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"404.erb"),  __FILE__))
			app_tree["app"]["views"]["500.html.erb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"500.erb"),  __FILE__))
			app_tree["app"]["views"]["404.html.slim"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"404.slim"),  __FILE__))
			app_tree["app"]["views"]["500.html.slim"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"500.slim"),  __FILE__))
			app_tree["app"]["views"]["404.html.haml"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"404.haml"),  __FILE__))
			app_tree["app"]["views"]["500.html.haml"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"500.haml"),  __FILE__))

			# set up the assets folder
			app_tree["assets"] ||= {}
			app_tree["assets"]["stylesheets"] ||= {}
			app_tree["assets"]["javascripts"] ||= {}
			app_tree["assets"]["javascripts"]["websocket.js"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"websockets.js"),  __FILE__)).gsub('appname', ARGV[1])
			app_tree["assets"]["welcome.html"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"welcome_page.html"),  __FILE__)).gsub('appname', ARGV[1])

			# app core files.
			app_tree["environment.rb"] ||= IO.read ::File.expand_path(File.join("..", "..", "resources" ,"environment.rb"),  __FILE__)
			app_tree["routes.rb"] ||= IO.read ::File.expand_path(File.join("..", "..", "resources" ,"routes.rb"),  __FILE__)
			app_tree["rakefile"] ||= IO.read ::File.expand_path(File.join("..", "..", "resources" ,"rakefile"),  __FILE__)
			app_tree["Procfile"] ||= ""
			app_tree["Procfile"] << "\nweb: bundle exec ruby ./#{ARGV[1]} -p $PORT\n"
			app_tree["Gemfile"] ||= ''
			app_tree["Gemfile"] << "source 'https://rubygems.org'\n\n####################\n# core gems\n\n# include the basic plezi framework and server\ngem 'plezi', '~> #{Plezi::VERSION}'\n"
			app_tree["Gemfile"] << IO.read( ::File.expand_path(File.join("..", "..", "resources" ,"Gemfile"),  __FILE__))
			app_tree["Gemfile"] << "\n\n\nruby '#{RUBY_VERSION}'\n"

			# set up config files
			app_tree["config"] ||= {}
			app_tree["config"]["oauth.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"oauth_config.rb"),  __FILE__))
			app_tree["config"]["active_record.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"db_ac_config.rb"),  __FILE__))
			app_tree["config"]["sequel.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"db_sequel_config.rb"),  __FILE__))
			app_tree["config"]["datamapper.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"db_dm_config.rb"),  __FILE__))
			app_tree["config"]["haml.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"haml_config.rb"),  __FILE__))
			app_tree["config"]["slim.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"slim_config.rb"),  __FILE__))
			app_tree["config"]["i18n.rb"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"i18n_config.rb"),  __FILE__))
			app_tree["config"]["redis.rb"] ||= (IO.read(::File.expand_path(File.join("..", "..", "resources" ,"redis_config.rb"),  __FILE__))).gsub('appsecret', "#{ARGV[1]}_#{SecureRandom.hex}")

			#set up database stub folders
			app_tree["db"] ||= {}
			app_tree["db"]["migrate"] ||= {}
			app_tree["db"]["fixtures"] ||= {}
			app_tree["db"]["config.yml"] ||= IO.read(::File.expand_path(File.join("..", "..", "resources" ,"database.yml"),  __FILE__))

			#set up the extras folder, to be filled with future goodies.
			# app_tree["extras"] ||= {}
			# app_tree["extras"]["config.ru"] ||= IO.read ::File.expand_path(File.join("..", "..", "resources" ,"config.ru"),  __FILE__)

			#set up I18n stub
			app_tree["locales"] ||= {}
			app_tree["locales"]["en.yml"] ||= IO.read ::File.expand_path(File.join("..", "..", "resources" ,"en.yml"),  __FILE__)

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
			finalize
		end
		def finalize
			begin
				Dir.mkdir ARGV[1]
				puts "created the #{ARGV[1]} application directory.".green
			rescue Exception => e
				puts "the #{ARGV[1]} application directory exists - trying to rebuild (no overwrite).".pink
			end
			Dir.chdir ARGV[1]
			puts "starting to write template data...".red
			puts ""
			write_files app_tree
			File.chmod 0775, "#{ARGV[1]}"
			puts "tried to update execution permissions. this is system dependent and might have failed.".pink
			puts "use: chmod +x ./#{ARGV[1]} to set execution permissions on Unix machines."
			puts ""
			puts "done."
			puts "\n#{@end_comments.join("\n")}" unless @end_comments.empty?
			puts ""
			puts "please change directory into the app directory: cd #{ARGV[1]}"
			puts ""
			puts "run the #{ARGV[1]} app using: ./#{ARGV[1]} or using: plezi s"
			puts ""
		end

		def write_files files, parent = "."
			if files.is_a? Hash
				files.each do |k, v|
					if v.is_a? Hash
						begin
							Dir.mkdir k
							puts "    created #{parent}/#{k}".green
						rescue Exception => e
							puts "    exists #{parent}/#{k}".red
						end
						Dir.chdir k
						write_files v, (parent + "/" + k)
						Dir.chdir ".."
					elsif v.is_a? String
						if ::File.exists? k
							if false #%w{Gemfile rakefile.rb}.include? k
								# old = IO.read k
								# old = (old.lines.map {|l| "\##{l}"}).join
								# IO.write k, "#####################\n#\n# OLD DATA COMMENTED OUT - PLEASE REVIEW\n#\n##{old}\n#{v}"
								# puts "    #{parent}/#{k} WAS OVERWRITTEN, old data was preserved by comenting it out.".pink
								# puts "    #{parent}/#{k} PLEASE REVIEW.".pink
								# @end_comments << "#{parent}/#{k} WAS OVERWRITTEN, old data was preserved by comenting it out. PLEASE REVIEW."
							else
								puts "    EXISTS(!) #{parent}/#{k}".red
							end
						else
							IO.write k, v
							puts "    wrote #{parent}/#{k}".yellow
						end
					end
				end
			end
		end
	end

end
