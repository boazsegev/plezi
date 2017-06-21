# finish with `exit` if running within `irb`
require 'plezi'
class ChatServer
  def index
    "Use Websockets to connect."
  end
  def on_open
    return close unless params['id']
    @name = params['id']
    subscribe channel: "chat"
    publish channel: "chat", message: "#{@name} joind the chat."
    write "Welcome, #{@name}!"
    # if we have Redis
    if(Iodine.default_pubsub.is_a? Iodine::PubSub::RedisEngine)
      # We'll add the name to the list of people in the chat.
      # Blocks are used as event callbacks and are executed asynchronously.
      Iodine.default_pubsub.send("SADD", "chat_members", @name) do
        # after the name was added, we'll get all the current people in the chat
        Iodine.default_pubsub.send("SMEMBERS", "chat_members") do |members|
          # By now, we're outside the Websocket connection's lock.
          # To safely access the connection, we'll use `defer`
          defer { write "Currently in the chatroom: #{members.join ', '}" }
        end
      end
    end
  end
  def on_close
    publish channel: "chat", message: "#{@name} joind the chat."
    # if we have Redis
    Iodine.default_pubsub.send("SREM", "chat_members", @name) if(Iodine.default_pubsub.is_a? Iodine::PubSub::RedisEngine)
  end
  def on_message data
    publish channel: "chat", message: "#{@name}: #{data}"
  end
end
path_to_client = File.expand_path( File.dirname(__FILE__) )
Plezi.templates = path_to_client
Plezi.route '/', ChatServer
