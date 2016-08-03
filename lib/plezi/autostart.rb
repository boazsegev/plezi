module Plezi
  protected

  def self.set_autostart
    if @plezi_autostart.nil?
      @plezi_autostart = true
      at_exit do
        next if @plezi_autostart == false
        ::Iodine::Rack.app = ::Plezi.app
        ::Iodine.threads ||= 16
        ::Iodine.start
      end
    end
  end
end
