
module Plezi

	module_function

	# Defers any missing methods to the GReactor Library.
	def method_missing name, *args, &block
		return super unless REACTOR_METHODS.include? name
		::GReactor.send name, *args, &block
	end
	# Defers any missing methods to the GReactor Library.
	def respond_to_missing?(name, include_private = false)
		REACTOR_METHODS.include?(name) or super
	end

	protected

	REACTOR_METHODS = ::GReactor.public_methods(false)

end

