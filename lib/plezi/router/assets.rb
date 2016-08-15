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
          if data.is_a?(String)
            FileUtils.mkpath File.dirname(name)
            IO.binwrite(name, data)
          end
          response['X-Sendfile'.freeze] = name
          response.body = File.open(name)
          true
        end
      else
        def index
          name = File.join(Plezi.assets, *params['*'.freeze]).freeze
          data = ::Plezi::AssetBaker.bake(name)
          IO.binwrite(name, data) if data.is_a?(String)
          if File.exist? name
            response['X-Sendfile'.freeze] = name
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
  # This module is used for asset "baking" (or "belated baking"). It allows us to easily register and support new types of assets.
  module AssetBaker
    @drivers = {}
    # Registers a new Asset Driver of a specific extension (i.e. "css", "js", etc')
    #
    # Multiple Asset Drivers can be registered for the same extension. The will be attempted in the order of their registration.
    #
    # An Asset Drivers is an object that responsd to `.call(target)`.
    # If the traget is newly rendered, the driver should return the rendered text.
    # If the asset didn't change since the last time `.call(target)` was called, the driver should return 'true' (meanning, yet, the asset exists, it's the same).
    # If the driver doesn't locate the asset, it should return `nil` or `false`, indicating the next driver should be attempted.
    def self.register(ext, driver)
      (@drivers[".#{ext}".freeze] ||= [].to_set) << driver
    end

    # @private
    # called by Plezi when in need of baking an asset.
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
