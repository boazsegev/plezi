# encoding: UTF-8

if defined? I18n
	# set up i18n locales paths
	I18n.load_path = Dir[Root.join('locales', '*.{rb,yml}').to_s]

	# set default locale, if not english
	# I18n.default_locale = :ru
end
			