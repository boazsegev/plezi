# Replace this sample with real code.
class ExampleCtrl
  # HTTP
  def index
    # any String returned will be appended to the response. We return a String.
    render 'welcome'
  end

  # Websockets
  def on_open
    subscribe channel: "chat"
    write 'Welcome to appname!'
    @handle = params['id'.freeze] || 'Somebody'
    publish channel: "chat", message: "#{ERB::Util.html_escape @handle} joind us :-)"
  end
  def on_message(data)
    data = ERB::Util.html_escape data
    publish channel: "chat", message: data
  end

  def on_close
    publish channel: "chat", message: "#{@handle} left us :-("
  end

end
