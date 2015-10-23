
module Plezi

	module_function

	# Defers any missing methods to the Iodine Library.
	def method_missing name, *args, &block
		return super unless REACTOR_METHODS.include? name
		::Iodine.__send__ name, *args, &block
	end
	# Defers any missing methods to the Iodine Library.
	def respond_to_missing?(name, include_private = false)
		REACTOR_METHODS.include?(name) || super
	end

	protected

	REACTOR_METHODS = ::Iodine.public_methods(false)

end

