require 'fileutils'
require 'set'
module Plezi
  module Base
    class Assets
      if ENV['RACK_ENV'.freeze] == 'production'.freeze
        def index
          name = File.join(Plezi.assets, *params['*'.freeze])
          data = ::Plezi::AssetBaker.bake(name)
          return false unless data
          name = File.join((Iodine::Rack.public || Plezi.assets), *params['*'.freeze])
          FileUtils.mkpath File.dirname(name)
          IO.binwrite(name, data)
          response['X-Sendfile'] = name
          response.body = File.open(name)
          true
        end
      else
        def index
          name = File.join(Plezi.assets, *params['*'.freeze])
          data = ::Plezi::AssetBaker.bake(name)
          return false unless data
          name = File.join(Plezi.assets, *params['*'.freeze])
          IO.binwrite(name, data)
          response['X-Sendfile'] = name
          response.body = File.open(name)
          true
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
