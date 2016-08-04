module Plezi
  protected

  @plezi_finalize = nil
  def plezi_finalize
    if @plezi_finalize.nil?
      @plezi_finalize = true
      @plezi_finalize = 1
    end
  end
  @plezi_initialize = nil
  def self.plezi_initialize
    if @plezi_initialize.nil?
      @plezi_initialize = true
      @plezi_autostart = true if @plezi_autostart.nil?
      at_exit do
        next if @plezi_autostart == false
        ::Iodine::Rack.app = ::Plezi.app
        ::Iodine.threads ||= 16
        ::Iodine.start
      end
    end
  end
end
