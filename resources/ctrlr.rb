# Replace this sample with real code.
class RootController
  # HTTP
  def index
    # any String returned will be appended to the response. We return a String.
    render 'welcome'
  end

  # Websockets
  def on_message(data)
    data = ERB::Util.html_escape data
    print data
    broadcast :print, data
  end

  def on_open
    print 'Welcome to appname!'
    @handle = params['id'.freeze] || 'Somebody'
    broadcast :print, "#{@handle} joind us :-)"
  end

  def on_close
    broadcast :print, "#{@handle} left us :-("
  end

  protected

  def print(data)
    response << data
  end
end
