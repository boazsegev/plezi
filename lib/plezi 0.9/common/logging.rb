
module Plezi

	#######################
	## Logging
	module_function

	# the logger object
	@logger = ::Logger.new(STDOUT)

	# gets the active logger
	def logger
		@logger
	end
	# gets the active STDOUT copy, if exists
	def logger_copy
		@copy_to_stdout
	end

	# create and set the logger object. accepts:
	# log_file:: a log file name to be used for logging
	# copy_to_stdout:: if false, log will only log to file. defaults to true.
	def create_logger log_file = STDOUT, copy_to_stdout = false
		@copy_to_stdout = ( copy_to_stdout ? (::Logger.new(STDOUT)) : false )
		@logger = ::Logger.new(log_file)
	end
	alias :set_logger :create_logger

	# writes a raw line to the log\
	def log_raw line
		@logger << line
		@copy_to_stdout << line if @copy_to_stdout
	end

	# logs info
	def log data
		@logger.info data
		@copy_to_stdout.info data if @copy_to_stdout
	end
	# logs info
	def info data
		@logger.info data
		@copy_to_stdout.info data if @copy_to_stdout
	end
	# logs warning
	def warn data
		@logger.warn data
		@copy_to_stdout.warn data if @copy_to_stdout
	end
	# logs errors
	def error data
		@logger.error data
		@copy_to_stdout.error data if @copy_to_stdout
	end
	# logs a fatal error
	def fatal data
		@logger.fatal data
		@copy_to_stdout.fatal data if @copy_to_stdout
	end
end
