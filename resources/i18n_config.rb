# encoding: UTF-8

if defined? I18n
	# set up i18n locales paths
	I18n.load_path = Dir[Root.join('locales', '*.{rb,yml}').to_s]

	# This will prevent certain errors from showing up.
	I18n.enforce_available_locales = false
	
	# set default locale, if not english
	# I18n.default_locale = :ru



	##########
	# Add shortcuts for the I18n methods into the main scope (available to all)
	# calls the I18n.translate with the arguments specified.
	# you can use the `t` alias.
	def translate *args
		I18n.t *args
	end
	alias :t :translate

	# calls the I18n.localize with the arguments specified.
	# you can use the `l` alias.
	def localize *args
		I18n.l *args		
	end
	alias :l :localize


	# this class can be used as a controller to set the locale and re-write the request path,
	# so that : /en/welcome, is translated to /welcome?locale=en
	class I18nReWrite
		# using the before filter and regular expressions to make some changes.
		def before
			# this will create a string formatted like this: "en|fr|ru" , depending on available locales:
			#       I18n.available_locales.join "|"
			# we will use it in a regular expression to check if the route starts with a locale
			result = request.path_info.match /^\/(#{   I18n.available_locales.join "|"   })($|\/.*)/
			if result
				# set the locale
				params["locale"] = I18n.locale = result[1].to_sym
				# rewrite the request path, extracting the locale
				request.path_info = result[2].to_s
			end
			return false
		end
	end


end
			