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

end
			