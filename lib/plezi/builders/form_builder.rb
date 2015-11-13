require 'plezi/builders/builder'

module Plezi

	module Base

		module FormBuilder

			FORM_BUILDERS = %w{ Slim ERB }
			MODEL_BUILDERS = %w{ Squel }

			DB_TYPES = %w{primary_key string text integer float decimal datetime time date binary boolean}

			@gem_root = ::Plezi::Builder::GEM_ROOT
			def self.parse_args
				return unless ARGS[0][0] == 'g'
				struct = {}
				ARGS[1..-1].each do |s|
					s = s.split /[\:\.]/
					raise "Cannot parse parameters - need to be defined as name.type or name:type." if s.count !=2
					struct[s[0]] = DB_TYPES[s[1].downcase] || (raise "Unrecognized type #{s[1]}.")
				end
				struct
			end
		end
	end
end
