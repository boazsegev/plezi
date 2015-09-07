# Plezi's Asynchronous Engine

(todo: write documentation)

Inside Plezi's core code is a pure Ruby IO reactor called [GReactor](https://github.com/boazsegev/GReactor) (Generic Reactor), a very powerful Asynchronous Workflow Engine that allows us to enjoy both Multi-Threading and Multi-Processing.

Although multi-threading is highly regarded, it should be pointed out that using the GReactor with just one thread is both faster and more efficient. But, since some tasks that take more time (blocking tasks) can't be broken down into smaller tasks, using a number of threads (and/or processes) is a better practice.

You can read more about the [GReactor](https://github.com/boazsegev/GReactor) and it's amazing features in it's [documentation](http://www.rubydoc.info/github/boazsegev/GReactor/master).

Here we will discuss the methods used for asynchronous processing of different tasks that allow us to break big heavy tasks into smaller bits, allowing our application to 'flow' and stay responsive even while under heavy loads.

## Asynchronous HTTP responses

Inside Plezi's core code is a pure Ruby HTTP and Websocket Server (and client) called [GRHttp](https://github.com/boazsegev/GRHttp) (Generic HTTP), which allows for native HTTP streaming.

Asynchronous HTTP method calls can be nested, but shouldn't be called on after the other.

i.e.:

```ruby
# right
response.stream_async {  response.stream_async {'do after'}; 'do first'  }
# wrong
response.stream_async {  "who's first?"  }
response.stream_async {  "I don't know..."  }
```

Since streaming is done asynchronously, and since Plezi is multi-threaded by default (this can be changed to single threaded, but is less recomended unless you know your code doesn't block - see `Plezi::Settings.max_threads = number`), Asynchronous HTTP method nesting makes sure that the code doesn't conflict and that race conditions don't occure within the same HTTP response.


#### GRHttp's `response.stream_async &block`

GRHttp's response object, which is accessed by the controller using the `response` method (or the `@response` object), allows easy access to HTTP streaming.

For example (run this in the terminal using `irb`):

```ruby
require `plezi`

class MyController
    def index
        response.stream_async do
            response << "This will stream.\n"
            response.stream_async do
                response << "Streaming can be nested."
            end
        end
    end
end

listen
route '/', MyController

exit
```

As noted above, `response.stream_async` calls should always be nested and never called in 'parallel'.

Calling `response.stream_async`

#### GRHttp's `response.stream_array enum, &block`

To make nesting easier, GRHttp's response object provides the `response.stream_array enum, &block` method.

Here's our modified example:

```ruby
require `plezi`

class MyController
    def index
        data = ["This will stream.\n", "Streaming can be nested."]
        response.stream_array(data) {|s| response << s}
    end
end

listen
route '/', MyController

exit
```

You can also add data to the array while 'looping', which allows you to use the array as a 'flag' for looped streaming. The following is a very limited example, which could be used for "lazy loading" data from a database, in order to save on system resources or send large table data using JSON "packets".

```ruby
require `plezi`

class MyController
    def index
        data = ["This will stream.\n", "Streaming can be nested."]
        flag = [true]
        response.stream_array(flag) do
            response << data.shift
            flag << true unless data.empty?
        end
    end
end

listen
route '/', MyController

exit
```



## Asynchronous code execution

[GReactor](https://github.com/boazsegev/GReactor) (Generic Reactor), a very powerful Asynchronous Workflow Engine which offers a very intuitve and easy to use API both for queuing code snippets (blocks / methods) and for schedualing non-persistent timed events (future timed events are discarded during shutdown and need to be re-initiated).

### The Asynchronous "Queue"

`GReactor` (in short: `GR`) offers a number of methods that allow us to easily queue code execution.


#### `GR.run_async(arg1, arg2, arg3...) {block}`

`GR.run_async` takes arguments to be passed to a block of code prior to execution. This allows us to seperate the `Proc` object creation fron the data handling and possibly (but not always) optimize our code.

For example:

```ruby
require `plezi`

class MyController
    def index
        GR.run_async(Time.now) {|t| puts "Someone poked me at: #{t}"} # maybe send an email?
        "Hello World"
    end
end

listen
route '/', MyController

exit
```

#### `GR.callback(object, method, arg1, arg2...) {|returned_value| callback block}`

Another common method imployed is the `GR.callback`, which allows us to layer asynchronous code:

```ruby
require `plezi`

class MyController
    def index
        GR.callback(self, :print_poke, Time.now) { puts "Printed poke."}
        "Hello World"
    end
    protected
    def print_poke time
        puts "Someone poked me at: #{time}"
    end
end

listen
route '/', MyController

exit
```



## Timed events

## The Graceful Shutdown

