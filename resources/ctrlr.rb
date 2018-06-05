# Replace this sample with real code.
class ExampleCtrl
  CHANNEL = "chat".freeze
  # HTTP
  def index
    # any String returned will be appended to the response. We return a String.
    render 'welcome'
  end

  # Websockets
  def on_open
    subscribe CHANNEL
    write 'Welcome to appname!'
    @handle = params['id'.freeze] || 'Somebody'
    publish CHANNEL, "#{ERB::Util.html_escape @handle} joind us :-)"
  end
  def on_message(data)
    data = ERB::Util.html_escape data
    publish CHANNEL, data
  end

  def on_close
    publish CHANNEL, "#{@handle} left us :-("
  end

end
