require 'thread'

module Plezi
  module Base
    class Route
      attr_reader :prefix, :controller

      def initialize(path, controller)
        raise 'Controller should be a class object' unless controller.is_a?(Class)
        @route_id = "Route#{object_id.to_s(16)}".to_sym
        Thread.current[@route_id] ||= {}
        m = path.match /([^\:\(\*]*)(.*)/
        @prefix = m[1].chomp '/'.freeze
        @prefix = '/'.freeze if @prefix.nil? || @prefix == ''.freeze
        @prefix_length = @prefix.length
        @controller = controller
        @param_names = []
        @origial = path.dup.freeze
        controller.include Plezi::Base::Controller
        path2regex(m[2])
      end

      def call(request, response)
        return unless match(request.path_info)
        controller.new
        controller.___respond(request, response, Thread.current[@route_id])
      end

      def fits_params(path)
        params = Thread.current[@route_id].clear
        pa = path[(@prefix_length + 1)..-1].split('/')
        return false unless @params_range.include?(pa.length)
        @param_names.each { |key| params[key] = pa.shift }
        true
      end

      def match(req_path)
        req_path.start_with?(@prefix) && fits_params(req_path)
      end

      def path2regex(postfix)
        pfa = postfix.split '/'
        start = 0; stop = 0
        optional = false
        while pfa.any?
          name = pfa.shift
          raise "#{name} is not a valid path section in #{@origial}" if /^(\:[\w\d]+)|(\(\:[\w\d\.\[\]]+\))$/.match(name).nil?
          if name[0] == ':'
            raise "Cannot have a required parameter after an optional parameter in #{@origial}" if optional
            @param_names << name[1..-1].freeze
          elsif name[0] == '('
            optional = true
            @param_names << name[2..-2].freeze
          elsif name[0] == '*'
            stop += 999_999
            break
          else
            raise "invalid path section #{name} in #{@origial}"
          end
          optional ? (stop += 1) : (start += 1)
        end
        @params_range = (start..(start + stop))
      end
    end
  end
end
