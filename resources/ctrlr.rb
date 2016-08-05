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

  # write is inherites when a Websocket connection is opened.
  #
  # Inherited functions aren't exposed (for our security), so we need to wrap it.
  def print(data)
    write data
  end
end
