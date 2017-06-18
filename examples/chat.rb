# finish with `exit` if running within `irb`
require 'plezi'
class ChatServer
  def index
    render 'client'
  end
  def on_open
    return close unless params['id']
    @name = params['id']
    subscribe channel: "chat"
    publish channel: "chat", message: "#{@name} joind the chat."
    write "Welcome, #{@name}!"
  end
  def on_close
    publish channel: "chat, message: "#{@name} joind the chat."
  end
  def on_message data
    publish channel: "chat", message: "#{@name}: #{data}"
  end
end
path_to_client = File.expand_path( File.dirname(__FILE__) )
Plezi.templates = path_to_client
Plezi.route '/', ChatServer
