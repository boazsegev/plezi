require 'fileutils'
require 'set'
module Plezi
  module Base
    class Assets
      if ENV['RACK_ENV'.freeze] == 'production'.freeze
        def index
          name = File.join(Plezi.assets, *params['*'.freeze]).freeze
          data = ::Plezi::AssetBaker.bake(name)
          return false unless data
          name = File.join(Iodine::Rack.public, request.path_info[1..-1]).freeze if Iodine::Rack.public
          FileUtils.mkpath File.dirname(name)
          IO.binwrite(name, data)
          response['X-Sendfile'] = name
          response.body = File.open(name)
          true
        end
      else
        def index
          name = File.join(Plezi.assets, *params['*'.freeze]).freeze
          data = ::Plezi::AssetBaker.bake(name)
          IO.binwrite(name, data) if data.is_a?(String)
          if File.exist? name
            response['X-Sendfile'] = name
            response.body = File.open(name)
            return true
          end
          false
        end
      end

      def show
        index
      end
    end
  end
  module AssetBaker
    @drivers = {}
    def self.register(ext, driver)
      (@drivers[".#{ext}".freeze] ||= [].to_set) << driver
    end

    def self.bake(name)
      ret = nil
      ext = File.extname name
      return false if ext.empty?
      driver = @drivers[ext]
      return false if driver.nil?
      driver.each { |d| ret = d.call(name); return ret if ret }
      nil
    end
  end
end
require 'plezi/render/sass.rb'
