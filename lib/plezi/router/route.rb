require 'plezi/controller/controller'

module Plezi
   module Base
      class Route
         attr_reader :prefix, :controller, :param_names

         def initialize(path, controller)
            @route_id = "Route#{object_id.to_s(16)}".to_sym
            @params_range = (0..0)
            m = path.match(/([^\:\(\*]*)(.*)/)
            @prefix = m[1].chomp('/'.freeze)
            if @prefix.nil? || @prefix == ''.freeze
               @prefix = '/'.freeze
               @prefix_length = 1
            else
               @prefix = "/#{@prefix}" if @prefix[0] != '/'.freeze
               @prefix_length = @prefix.length + 1
            end
            @controller = controller
            @param_names = []
            @origial = path.dup.freeze
            prep_params(m[2])
            self.class.qp
            case @controller
            when Class
               prep_controller
            when Regexp
               raise "Rewrite Routes can't contain more then one parameter to collect" if @param_names.length > 1
            else
               raise 'Controller should be a class object' unless controller.is_a?(Class)
            end
         end

         def call(request, response)
            return nil unless match(request.path_info, request)
            c = @controller.new
            c._pl_respond(request, response, Thread.current[@route_id])
         end

         def fits_params(path, request)
            params = (Thread.current[@route_id] ||= {}).clear
            params.update request.params.to_h if request && request.params
            # puts "cutting: #{path[(@prefix_length)..-1] ? path[(@prefix_length + 1)..-1] : 'nil'}"
            pa = (path[@prefix_length..-1] || ''.freeze).split('/'.freeze)
            # puts "check param count: #{pa}"
            return false unless @params_range.include?(pa.length)
            @param_names.each do |key|
               next if pa[0].nil?
               self.class.qp.normalize_params(params, Plezi.try_utf8!(Rack::Utils.unescape(key)),
                                              Plezi.try_utf8!(Rack::Utils.unescape(pa.shift)), 100)
            end
            params['*'.freeze] = pa unless pa.empty?
            true
         end

         def match(req_path, request = nil)
            # puts "#{req_path} starts with #{@prefix}? #{req_path.start_with?(@prefix)}"
            req_path.start_with?(@prefix) && fits_params(req_path, request)
         end

         def prep_params(postfix)
            pfa = postfix.split '/'.freeze
            start = 0; stop = 0
            optional = false
            while pfa.any?
               name = pfa.shift
               raise "#{name} is not a valid path section in #{@origial}" unless /^((\:[\w\.\[\]]+)|(\(\:[\w\.\[\]]+\))|(\*))$/.match(name)
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
            unless (@param_names.include? 'id'.freeze) || stop >= 999_999
               @param_names << 'id'.freeze
               stop += 1
            end
            @params_range = (start..(start + stop))
            @param_names.freeze
            @params_range.freeze
         end

         def prep_controller
            @controller.include Plezi::Controller
         end

         def self.qp
            @qp ||= ::Rack::QueryParser.new(Hash, 65_536, 100)
         end
      end
      class RouteRewrite < Route
         def call(request, _response)
            return nil unless match(request.path_info, request)
            params = Thread.current[@route_id]
            return nil unless controller =~ params[@param_names[0]]
            request.path_info = "/#{params.delete('*'.freeze).to_a.join '/'}"
            request.params.update params
            nil
         end
      end
   end
end
