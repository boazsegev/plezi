# The Ruby Chatroom - Websockets with Plezi

Using Plezi, anyone can easily create a web application that has advanced features such as **websockets**, data pushing and callbacks.

The chatroom application is a great way to discover these advanced features and the Plezi framework's native WebSocket support.

###Coding is the way to discover Plezi

When I was little, my father tried to teach me to swim... in other words, he throw me in the pool and let the chips fall where they may.

I was on the verge of drowning for the first few weeks, but looking back I am very thankful for the experience. You can hardly learn anything about swimming without entering the pool...

So let's start with getting wet - writing the code - and then maybe refine our understanding a bit by taking the code apart.

###Before we start - installing Plezi

I assume that you have already [installed Ruby with RubyGems](https://www.ruby-lang.org/en/installation/), if not, do it now. I recommend [installing Ruby and RubyGems using rvm](http://rvm.io/rvm/install).

once ruby and rubygems are installed, it's time to install Plezi. in your terminal window, run:

```
$ gem install plezi
```

depending on your system and setup, you might need to enter a password or use the sudo command to install new gems:

```
$ sudo gem install plezi
```

That's it.

##The Ruby Code (chatroom server)

We can create an Plezi application using the `$ plezi new myapp` command, but that's too easy - we want it hardcore.

Let's create an application folder called `mychat` and save our code in a file called `mychat.rb` in our application folder.

The first bit of code tells the Unix bash to run this file as a ruby file, just in case we want to make this file into a Unix executable (for us Unix and BSD people).

```ruby
#!/usr/bin/env ruby
# encoding: UTF-8
```

This next bit of code imports Plezi into our program and allows us to use the Plezi framework in our application.

```ruby
require 'plezi'
```

Then there is the part where we define the `ChatController` class... We'll talk about this piece of code later on. for now, I will just point out that this class doesn't inherit any special controller class.

Let's write a short stub which we will fill in later.

```ruby
class ChatController
# ...we'll fill this in later...
end
```
Next, we set find the root folder where our application exists - we will use this to tell plezi where our html files, templates and assets are stored (once we write any of them).

```ruby
# Using pathname extentions for setting public folder
require 'pathname'
# set up the Root object for easy path access.
Root = Pathname.new(File.dirname(__FILE__)).expand_path
```

Then, we set up the Plezi service's parameters - parameters which Plezi will use to create our main service and host.

A service, in this case, is realy just a nice word for the Plezi server (which might have a number of services or hosts). We will have only one service and one host, so it's very easy to set up.

As you can see, some options are there for later, but are disabled for now.

- **root**: this option defines the folder from which Plezi should serve static files (html files, images etc'). We will not be serving any static files at the moment, so this option is disabled.

- **assets**: this option tells plezi where to look for asset files that might need rendering - such as Sass and Coffee-Script files... We will not be using these features either, so that's out as well.

- **assets_public**: this option tells plezi which route is the one where assets are attached to (it defaults to '/assets'). We aren't using assets, so that's really not important.

- **_templates_**: this option tells Plezi where to look for template files (.haml / .erb files). Since we will use a template file for our HTML, let's go ahead and create a subfolder called `views` and set that as our templates source folder.

- **ssl**: this option, if set to true, will make our service into an SSL/TSL encrypted service (as well as our websocket service)... we can leave this off for now - it's actually hardly ever used since it's usually better to leave that to our production server.

```ruby
service_options = {
	# root: Root.join('public').to_s,
	# assets: Root.join('assets').to_s,
	# assets_public: '/',
	templates: Root.join('views').to_s,
	ssl: false
}
```

Next we call the `listen` command - this command actually creates the service.

The port plezi uses by default is 3000 [http://localhost:3000/](http://localhost:3000/). By not defining a port, we allowed ourselves to either use the default port (3000) or decide the port when we run our application (i.e. `./mychat.rb -p 8080`).

```ruby
listen service_options
```

(if you want to force a specific port, i.e. 80, write `listen 80, service_options` - but make sure you are allowed to use this port)

Last, but not least, we tell Plezi to connect the root of our web application to our ChatController - in other words, make sure the root _path_ ('/') is connected to the ChatController class.

```ruby
route '/', ChatController
```

Plezi controller classes are like virtual folders with special support for RESTful methods (`index`, `new`, `save`, `update`, `delete`), HTTP filters and helpers (`before`, `after`, `redirect_to`, `send_data`), WebSockets methods (`on_connect`, `on_message(data)`, `on_disconnect`), and WebSockets filters and helpers (`pre-connect`, `broadcast`, `collect`).

Plezi uses a common special parameter called 'id' to help with all this magic... if we don't define this parameter ourselves, Plezi will try to append this parameter to the end our route's path. So, actually, our route looks like this:

```ruby
route '/(:id)', ChatController
```

###The Controller - serving regular data (HTTP)

Let's take a deeper look into our controller and start filling it in...

####serving the main html template file (index)

The first thing we want our controller to do, is to serve the HTML template we will write later on. We will use a template so we can add stuff later, maybe.

Since controllers can work like virtual folders with support for RESTful methods, we can define an `index` method to do this simple task:

```ruby
def index
	#... later
end
```

Plezi has a really easy method called `render` that creates (and caches) a rendering object with our template file's content and returns a String of our rendered template.

Lets fill in our `index` method:

```ruby
class ChatController
	def index
		response['content-type'] = 'text/html'
		response << render(:chat)
		true
	end
end
```

Actually, some tasks are so common - like sending text in our HTTP response - that Plezi can helps us along. If our method should return a String object, that String will be appended to the response.

Let's rewrite our `index` method to make it cleaner:

```ruby
class ChatController
	def index
		response['content-type'] = 'text/html'
		render(:chat)
	end
end
```

When someone will visit the root of our application (which is also the '_root_' of our controller), they will get the our ChatController#index method. 

We just need to remember to create a 'chat' template file (`chat.html.erb` or `chat.html.haml`)... but that's for later.

####Telling people that we made this cool app!

there is a secret web convention that allows developers to _sign_ their work by answering the `/people` path with plain text and the names of the people who built the site...

With Plezi, that's super easy.

Since out ChatController is at the root of ou application, let's add a `people` method to our ChatController:

```ruby
def people
	"I wrote this app :)"
end
```

Plezi uses the 'id' parameter to recognize special paths as well as for it's RESTful support. Now, anyone visiting '/people' will reach our ChatController#people method.

Just like we already discovered, returning a String object (the last line of the `people` method is a String) automatically appends this string to our HTTP response - cool :)

###The Controller - live input and pushing data (WebSockets)

We are building an advanced application here - this is _not_ another 'hello world' - lets start exploring the advanced stuff.

####Supporting WebSockets

To accept WebSockets connections, our controller must define an `on_message(data)` method.

Plezi will recognize this method and allow websocket connections for our controller's path (which is at the root of our application).

We will also want to transport some data between the browser (the client) and our server. To do this, we will use [JSON](http://en.wikipedia.org/wiki/JSON), which is really easy to use and is the same format used by socket.io.

We will start by formatting our data to JSON (or closing the connection if someone is sending corrupt data):

```ruby
def on_message data
	begin
		data = JSON.parse data
	rescue Exception => e
		response << {event: :error, message: "Unknown Error"}.to_json
		response.close
		return false
	end
end
```

####Pausing for software design - the Chatroom challange

To design a chatroom we will need a few things:

1. We will need to force people identify themselves by choosing nicknames - to do this we will define the `on_connect` method to refuse any connections that don't have a nickname.
2. We will want to make sure these nicknames are unique and don't give a wrong sense of authority (nicknames such as 'admin' should be forbidden) - for now, we will simply collect the nicknames from all the other active connections using the `collect` method and use that in our `on_connect` method.
3. We will want to push messages we recieve to all the other chatroom members - to do this we will use the `broadcast` method in our `on_message(data)` method.
4. We will also want to tell people when someone left the chatroom - to do this we can define an `on_disconnect` method and use the `broadcast` method in there.

We can use the :id parameter to collect the nickname.

the :id is an automatic parameter that Plezi appended to our path like already explained and it's perfect for our simple needs.

We could probably rewrite our route to something like this: `route '/(:id)/(:nickname)', ChatController` (or move the `/people` path out of the controller and use `'/(:nickname)'`)... but why work hard when we don't need to?

####Broadcasting chat (websocket) messages

When we get a chat message, with `on_message(data)`, we will want to broadcast this message to all  the _other_ ChatController connections.

Using JSON, our new  `on_message(data)` method can look something like this:

```ruby
def on_message data
	begin
		data = JSON.parse data
	rescue Exception => e
		response << {event: :error, message: "Unknown Error"}.to_json
		response.close
		return false
	end
	message = {}
	message[:message] = data["message"]
	message[:event] = :chat
	message[:from] = params[:id]
	message[:at] = Time.now
	broadcast :_send_message, message.to_json
end
```

let's write it a bit shorter... if our code has nothing important to say, it might as well be quick about it.

```ruby
def on_message data
	begin
		data = JSON.parse data
	rescue Exception => e
		response << {event: :error, message: "Unknown Error"}.to_json
		response.close
		return false
	end
	broadcast :_send_message, {event: :chat, from: params[:id], message: data["message"], at: Time.now}.to_json
end
```

Now that the code is shorter, let's look at that last line - the one that calls `broadcast`

`broadcast` is an interesing Plezi feature that allows us to tell all the _other_ connection to run a method. It is totally asynchroneos, so we don't wait for it to complete.

Here, we tell all the other websocket instances of our ChatController to run their `_send_message(msg)` method on their own connections - it even passes a message as an argument... but wait, we didn't write the `_send_message(msg)` method yet!

####The \_send_message method

Let's start with the name - why the underscore at the beginning?

Plezi knows that sometimes we will want to create public methods that aren't available as a path - remember the `people` method, it was automatically recognized as an HTTP path...

Plezi allows us to 'exclude' some methods from this auto-recogntion. protected methods and methods starting with an underscore (\_) aren't recognized by the Plezi router.

Since we want the `_send_message` to be called by the `broadcast` method - it must be a public method (otherwise, we will not be able to call it for _other_ connections, only for our own connection).

This will be our `_send_message` method:

```ruby
def _send_message data
	response << data
end
```

Did you notice the difference between WebSocket responses and HTTP?

In WebSockets, we don't automatically send string data (this is an important safeguard) and we must use the `<<` method to add data to the response stream.


####Telling people that we left the chatroom

Another feature we want to put in, is letting people know when someone enters or leaves the chatroom.

Using the `broadcast` method with the special `on_disconnect` websocket method, makes telling people we left an easy task... 

```ruby
def on_disconnect
	message = {event: :chat, from: '', at: Time.now}
	message[:message] = "#{params[:id]} left the chatroom."
	broadcast :_send_message, message.to_json if params[:id]
end
```

We will only tell people that we left the chatroom if our login was successful - this is why we use the `if params[:id]` statement - if the login fails, we will set the `params[:id]` to false.

Let's make it a bit shorter?

```ruby
def on_disconnect
	broadcast :_send_message, {event: :chat, from: '', at: Time.now, message: "#{params[:id]} left the chatroom."}.to_json if params[:id]
end
```

####The login process and telling people we're here

If we ever write a real chatroom, our login process will look somewhat different - but the following process is good enough for now and it has a lot to teach us...

First, we will ensure the new connection has a nickname (the connection was made to '/nickname' rather then the root of our application '/'):

```ruby
def on_connect
	if params[:id].nil?
		response << {event: :error, from: :system, at: Time.now, message: "Error: cannot connect without a nickname!"}.to_json
		response.close
		return false
	end
end
```

Easy.

Next, we will ask everybody else who is connected to tell us their nicknames - we will test the new nickname against this list and make sure the nickname is unique.

We will also add some reserved names to this list, to make sure nobody impersonates a system administrator... let's add this code to our `on_connect` method:

```ruby
	message = {from: '', at: Time.now}
	list = collect(:_ask_nickname)
	if (list + ['admin', 'system', 'sys', 'administrator']).include? params[:id]
		message[:event] = :error
		message[:message] = "The nickname '#{params[:id]}' is already taken."
		response << message.to_json
		params[:id] = false
		response.close
		return
	end
```

Hmm.. **collect**? what is the `collect` method? - well, this is a little bit of more Plezi magic that allows us to ask and collect information from all the _other_ active connections. This method returns an array of all the responses.

We will use `collect` to get an array of all the connected nicknames - we will write the `_ask_nickname` method in just a bit.

Then, if all is good, we will welcome the new connection to our chatroom. We will also tell the new guest who is already connected and broadcast their arrivale to everybody else...:

```ruby
		message = {from: '', at: Time.now}
		message[:event] = :chat
		if list.empty?
			message[:message] = "Welcome! You're the first one here."
		else
			message[:message] = "Welcome! #{list[0..-2].join(', ')} #{list[1] ? 'and' : ''} #{list.last} #{list[1] ? 'are' : 'is'} already here."
		end
		response << message.to_json
		message[:message] = "#{params[:id]} joined the chatroom."
		broadcast :_send_message, message.to_json
```

Let's make it just a bit shorter, most of the code ins't important enough to worry about readability... we can compact our `if` statement to an inline statement like this:

```ruby
		message[:message] = list.empty? ? "You're the first one here." : "#{list[0..-2].join(', ')} #{list[1] ? 'and' : ''} #{list.last} #{list[1] ? 'are' : 'is'} already in the chatroom"
```

We will also want to tweek the code a bit, so the nicknames are case insensative...

This will be our final `on_connect` method:

```ruby
def on_connect
	if params[:id].nil?
		response << {event: :error, from: :system, at: Time.now, message: "Error: cannot connect without a nickname!"}.to_json
		response.close
		return false
	end
	message = {from: '', at: Time.now}
	list = collect(:_ask_nickname)
	if ((list.map {|n| n.downcase}) + ['admin', 'system', 'sys', 'administrator']).include? params[:id].downcase
		message[:event] = :error
		message[:message] = "The nickname '#{params[:id]}' is already taken."
		response << message.to_json
		params[:id] = false
		response.close
		return
	end
	message[:event] = :chat
	message[:message] = list.empty? ? "You're the first one here." : "#{list[0..-2].join(', ')} #{list[1] ? 'and' : ''} #{list.last} #{list[1] ? 'are' : 'is'} already in the chatroom"
	response << message.to_json
	message[:message] = "#{params[:id]} joined the chatroom."
	broadcast :_send_message, message.to_json
end
```

####The \_ask_nickname method

Just like the `_send_message` method, this method's name starts with an underscore to make sure it is ignored by the Plezi router.

Since this message is used by the `collect` method to collect information (which will block our code), it's very important that this method will be short and fast - it might run hundreds of times (or more), depending how many people are connected to our chatroom...

```ruby
	def _ask_nickname
		return params[:id]
	end
```

###The Complete Ruby Code < (less then) 75 lines

This is our complete `mychat.rb` Ruby application code:

```ruby
#!/usr/bin/env ruby
# encoding: UTF-8

require 'plezi'

class ChatController
	def index
		response['content-type'] = 'text/html'
		render(:chat)
	end
	def people
		"I wrote this app :)"
	end
	def on_message data
		begin
			data = JSON.parse data
		rescue Exception => e
			response << {event: :error, message: "Unknown Error"}.to_json
			response.close
			return false
		end
		broadcast :_send_message, {event: :chat, from: params[:id], message: data["message"], at: Time.now}.to_json
	end
	def _send_message data
		response << data
	end
	def on_connect
		if params[:id].nil?
			response << {event: :error, from: :system, at: Time.now, message: 	"Error: cannot connect without a nickname!"}.to_json
			response.close
			return false
		end
		message = {from: '', at: Time.now}
		list = collect(:_ask_nickname)
		if ((list.map {|n| n.downcase}) + ['admin', 'system', 'sys', 'administrator']).include? params[:id].downcase
			message[:event] = :error
			message[:message] = "The nickname '#{params[:id]}' is already taken."
			response << message.to_json
			params[:id] = false
			response.close
			return
		end
		message[:event] = :chat
		message[:message] = list.empty? ? "You're the first one here." : "#{list[0..-2].join(', ')} #{list[1] ? 'and' : ''} #{list.last} #{list[1] ? 'are' : 'is'} already in the chatroom"
		response << message.to_json
		message[:message] = "#{params[:id]} joined the chatroom."
		broadcast :_send_message, message.to_json
	end

	def on_disconnect
		broadcast :_send_message, {event: :chat, from: '', at: Time.now, message: "#{params[:id]} left the chatroom."}.to_json if params[:id]
	end
	def _ask_nickname
		return params[:id]
	end
end

# Using pathname extentions for setting public folder
require 'pathname'
# set up the Root object for easy path access.
Root = Pathname.new(File.dirname(__FILE__)).expand_path

# set up the Plezi service options
service_options = {
	# root: Root.join('public').to_s,
	# assets: Root.join('assets').to_s,
	# assets_public: '/',
	templates: Root.join('views').to_s,
	ssl: false
}

listen service_options

# this routes the root of the application ('/') to our ChatController
route '/', ChatController
```

##The HTML - a web page with websockets

The [official websockets page](https://www.websocket.org) has great info about websockets and some tips about creating web pages with WebSocket features.

Since this isn't really a tutorial about HTML, Javascript or CSS, we will make it a very simple web page and explain just a few things about the websocket javascript...

...**this is probably the hardest part in the code** (maybe because it isn't Ruby).

Let us create a new file, and save it at `views/chat.html.erb` - this is our template file and Plezi will find it when we call `render :chat`.

`.erb` files allow us to write HTML like files with Ruby code inside. We could also use Haml (which has a nicer syntax), but for now we will keep things symple... so simple, in fact, we will start with no Ruby code inside.

Copy and paste the following into your `views/chat.html.erb` file - the `views` folder is the one we defined for the `templates` in the Plezi service options - remember?

Anyway, here's the HTML code, copy it and I'll explain the code in a bit:

```html
<!DOCTYPE html>
<head>
  <meta charset='UTF-8'>
  <style>
  	html, body {width: 100%; height:100%;}
  	body {font-size: 1.5em; background-color: #eee;}
  	p {padding: 0.2em; margin: 0;}
    .received { color: #00f;}
    .sent { color: #80f;}
    input, #output, #status {font-size: 1em; width: 60%; margin: 0.5em 19%; padding: 0.5em 1%;}
    input[type=submit] { margin: 0.5em 20%; padding: 0;}
    #output {height: 60%; overflow: auto; background-color: #fff;}
    .connected {background-color: #efe;}
    .disconnected {background-color: #fee;}
  </style>
  <script>
  	var websocket = NaN;
  	var last_msg = NaN;
  	function Connect() {
  		websocket = new WebSocket( (window.location.protocol.indexOf('https') < 0 ? 'ws' : 'wss') + '://' + window.location.hostname + (window.location.port == '' ? '' : (':' + window.location.port) ) + "/" + document.getElementById("input").value );
  	}
	function Init()
	{
		Connect()
		websocket.onopen = function(e) { update_status(); WriteStatus({'message':'Connected :)'})};
		websocket.onclose = function(e) { websocket = NaN; update_status(); };
		websocket.onmessage = function(e) {
			var msg = JSON.parse(e.data)
			last_msg = msg
			if(msg.event == 'chat') WriteMessage(msg, 'received')
			if(msg.event == 'error') WriteStatus(msg)
		};
		websocket.onerror = function(e) { websocket = NaN; update_status(); };
	}
	function WriteMessage( message, message_type )
	{
		if (!message_type) message_type = 'received'
		var msg = document.createElement("p");
		msg.className = message_type;
		msg.innerHTML = message.from + ": " + message.message;
		document.getElementById("output").appendChild(msg);
	}
	function WriteStatus( message )
	{
		document.getElementById("status").innerHTML = message.message;
	}
	function Send()
	{
		var msg = {'event':'chat', 'from':'me', 'message':document.getElementById("input").value}
		WriteMessage(msg, 'sent'); 
		websocket.send(JSON.stringify(msg));
	}
	function update_status()
	{
		if(websocket)
		{
			document.getElementById("submit").value = "Send"
			document.getElementById("input").placeholder = "your message goes here"
			document.getElementById("status").className = "connected"
		}
		else
		{
			document.getElementById("submit").value = "Connect"
			document.getElementById("input").placeholder = "your nickname"
			document.getElementById("status").className = "disconnected"
			if(last_msg.event != 'error') document.getElementById("status").innerHTML = "Please choose your nickname and join in..."
		}
	}
	function on_submit()
	{
		if(websocket)
		{
			Send()
		}
		else
		{
			Init()
		}
		document.getElementById("input").value = ""
	}
  </script>
</head>
<body>
	<div id='status' class='disconnected'>Please choose your nickname and join in...</div>
	<div id='output'></div>
	<form onsubmit='on_submit(); return false'>
		<input id='input' type='text' placeholder='your nickname.' value='' />
		<input type='submit' value='Connect' id='submit' />
	</form>
</body>
```

Our smart web page has three main components: the CSS (the stuff in the `style` tag), the Javascript (in the `script` tag) and the actual HTML.

All the interesting bits are in the Javascript.

The Javascript allows us to request a nickname, send a connection request to 'ws://localhost:3000/nickname' (where we pick up the nickname using the RESTful 'id' parameter), and send/recieve chat messages.

The CSS is just a bit of styling so the page doesn't look too bad.

The HTML is also very simple. We have one `div` element called `output`, one text input, a status bar (on top) and a submit button (with the word 'Send' / 'Connect').

I will go over some of the JavaScript highlights very quickly, as there are a lot of tutorials out there regarding websockets and javascript.

The main javascript functions we are using are:

* `connect` - this creates a new websockets object. this is fairly simple, even if a bit hard to read. there is a part there where instead of writing `ws://localhost:3000/nickname` we are dynamically producing the same string - it's harder to read but it will work also when we move the webpage to a real domain where the string might end up being `wss://www.mydomain.com/nickname`.
* `init` - this is a very interesting function that defines all the callbacks we might need for the websocket to actually work. 
* `WriteMessage` - this simple function adds text to the `output` element, adding the different styles as needed.
* `WriteStatus` - this function is used to update the status line.
* `update_status` - we use this function to update the status line when the websocket connects and disconnects from the server.
* `Send` - this simple function sends the data from the input element to the websocket connection.

##Congratulations!

Congratulations! You wrote your first Plezi chatroom :-)

Using this example we discovered that Plezi is a powerful Ruby framework that has easy and native support for both RESTful HTTP and WebSockets.

Plezi allowed us to easily write a very advanced application, while exploring exciting new features and discovering how Plezi could help our workflow.

There's a lot more to explore - enjoy :-)
