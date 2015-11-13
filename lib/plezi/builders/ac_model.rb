require 'plezi/builders/builder'

module Plezi

	module Base


		module ACModelBuilder
			@gem_root = ::Plezi::Builder::GEM_ROOT

			# ActiveRecord::Base.connection.tables
			# # Checks for existence of kittens table (Kitten model)
			# ActiveRecord::Base.connection.table_exists? 'kittens'

			# # Tells you all migrations run
			# ActiveRecord::Migrator.get_all_versions
			# # Tells you the current schema version
			# ActiveRecord::Migrator.current_version

			# # Check a column exists
			# column_exists?(:suppliers, :name)

			# # Check a column exists of a particular type
			# column_exists?(:suppliers, :name, :string)

			# # Check a column exists with a specific definition
			# column_exists?(:suppliers, :name, :string, limit: 100)
			# column_exists?(:suppliers, :name, :string, default: 'default')
			# column_exists?(:suppliers, :name, :string, null: false)
			# column_exists?(:suppliers, :tax, :decimal, precision: 8, scale: 2)

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

		# require 'sequel'

		# ## Connect to the database
		# DB = Sequel.sqlite('./ex1.db')

		# unless DB.table_exists? :posts
		#   DB.create_table :posts do
		#     primary_key :id
		#     varchar :title
		#     text :body
		#   end
		# end


	end
end
