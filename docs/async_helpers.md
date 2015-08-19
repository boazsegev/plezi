# Plezi's Asynchronous Engine

(todo: write documentation)

Inside Plezi's core code is a pure Ruby IO reactor called [GReactor](https://github.com/boazsegev/GReactor) (Generic Reactor), a very powerful Asynchronous Workflow Engine that allows us to enjoy both Multi-Threading and Multi-Processing.

Although multi-threading is highly regarded, it should be pointed out that using the GReactor with just one thread is both faster and more efficient. But, since some tasks that take more time (blocking tasks) can't be broken down into smaller tasks, using a number of threads (and/or processes) is better practice.

You can read more about the [GReactor](https://github.com/boazsegev/GReactor) and it's amazing features in it's [documentation](http://www.rubydoc.info/github/boazsegev/GReactor/master).

Here we will discuss the methods used for asynchronous processing of different tasks that allow us to break big heavy tasks into smaller bits, allowing our application to 'flow' and stay responsive even while under heavy loads.

## Asynchronous HTTP responses


#### GRHttp's `response.stream_async &block`

Inside Plezi's core code is a pure Ruby HTTP and Websocket Server (and client) called [GRHttp](https://github.com/boazsegev/GRHttp) (Generic HTTP), which allows for native HTTP streaming.



## Asynchronous code execution

#### `GR.run_async(arg1, arg2, arg3...) {block}`



#### `GR.callback(object, method, arg1, arg2...) {|returned_value| callback block}`


## Timed events

## The Graceful Shutdown

