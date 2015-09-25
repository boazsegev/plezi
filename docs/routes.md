# Plezi's Smart Routing System

In the core of Plezi's framework is a smart Object Oriented Router which actls like a "virtual folder" with RESTful routing and Websocket support.

RESTful routing and Websocket callback support both allow us to use conventionally named methods in our Controller to achive common tasks. Such names methods, as will be explored further on, include the `update`, `save` and `show` RESTful method names, as well as the `on_open`, `on_message(data)` and `on_close` Websocket callbacks.

## What is a Route?

Routes are what connects different URLs to different parts of our code.

We when we visit `www.example.com/users/index` we expect a different page than when we go to `www.example.com/users/1`. This is because we expect the first URL to provide a page with the list of users while we expect the second URL to show us just one user's page or data.

in the example above, all the requests to `www.example.com` end up at the same server and it is the server's inner workings - the server's inner router - that directs the `/users/index` to one part of our code and `/users/1` to another.

Plezi has an inner router which routes each request to the corresponding method or code.

\* It should be noted that except for file handling and the asset pipeline - which are file-system dependent - routes are case-sensitive.

## Defining a Route

We define a route using Plezi's `Plezi.route` method or the shortcut DSL method `route` (without the `Plezi.` part).

This method accept a String, or Regexp, that should point to a "group" of routes.

The method also requires either a class that "controls" that group of routes or a block of code that responds to that route.

Here are a two examples for valid routes. You can run the following script in the `irb` terminal:

```ruby
require 'plezi'

class UsersController
    def index
        "All Users"
    end
end

# the "/users" group can be extended. for now, it will only answer: "/users" or "/users/index"
# this is because that's all that UsersController defines.
Plezi.route "/users", UsersController

# this route isn't grouped under a controller. it will only answer "/people"
Plezi.route("/people") { "People" }

# this route includes a catch-all at the end and will catch anything that starts with "/stuff/" 
Plezi.route("/stuff/*") { "More and more stuff" }

# this is catch-all which will answer any requests not yet answered.
Plezi.route("*") { "Lost?" }

# this route will never be seen,
# because the catch-all route answers any request before it gets here.
Plezi.route("/never-seen") { "You cant see me..." }


exit
```

As you may have noticed, the route's order of creation was important and established an order of precedence.

If the order of precedence were not to exist, we couldn't create a catch-all route, in fear that it might respond to valid requests.

### The `:id` parameter

In order to manage route "groups", Plezi's router attmpt to add an optional `:id` parameter at the end of the route. This is only possible when the route doesn't end with a catch-all (if a catch-all exists, the `:id` parameter can't be isolated).

So, the following two routes are identical:

```ruby
require 'plezi'

class UsersController
    def index
        "All Users"
    end
end

Plezi.route "/users", UsersController

route "/users/(:id)", UsersController

exit
```

It's possible to add different optional parameters either before or after the (:id) parameter... but the (:id) parameter is special and it WILL effect the way the Controller reacts to the request - this is what allows the controller to react to RESTful requests (more information about this later on).

For example:

```ruby
require 'plezi'

class UsersController
    def index
        "All Users"
    end
    def show
        params[:name] ||= "unknown"
        "Your name is #{ params[:name] }... why are you looking for user id '#{ params[:id] }'?"
    end
end

# try visiting "/users/1/John"
route "/users/(:id)/(:name)", UsersController

exit
```

As you noticed, providing an `:id` parameter invoked the RESTful method `show`. This is only one possible outcome. We will discuss this more when we look at the Controller being used as a virtual folder and as we discuss about RESTful method.

### More inline parameters

Inline parameters come in more flavors:

* Required parameters signified only by the `:` sign. i.e. `'/users/:name'`.
* Optional parameters, as seen before. i.e. `'/users/(:name)'`.
* Required parameters matching a specific pattern, signified by the `:` sign with a `{pattern}`. i.e. `'/users/:date{[\d]{8}}'` (requiring 8 digit date, such as `'20151231'`).
* Optional parameters matching a specific pattern. i.e. `'/users/(:date){[\d]{8}}'` (optional 8 digit date, such as `'20151231'`).

Using inline parameters, it's possible to achive great flexability with the same route, allowing our code to be better organized. This is especially helpful when expecting data to be received using AJAX or when creating an accessible API for native apps to utilize.

It should be noted, that since a parameter matches against the whole of the pattern, parenthesis shouldn't be used and could cause parsing errors.

### Re-Write Routes

Sometimes, we want some of our routes to share common optional (or required) parameters. This is where "Re-Write" routes come into play.

A common use-case, is for setting the locale or language for the response.

To create a re-write route, we set the "controller" to false.

For Example:


```ruby
require 'plezi'

class UsersController
    def index
        case params[:locale]
        when 'sp'
            "Hola!"
        when 'fr'
            "Bonjour!"
        when 'ru'
            "Здравствуйте!"
        when 'jp'
            "こんにちは!"
        else
            "Hello!"
        end
    end
end

# this is the re-write route:
Plezi.route "/(:locale){en|sp|fr|ru|jp}/*", false

# this route inherits the `:locale`'s result
# try:
#   /fr/users
#   /ru/users
#   /en/users
#   /it/users # => isn't a valid locale
Plezi.route "/users", UsersController

exit
```

notice the re-write route contained a catch all. After Plezi version 0.11.3 this catch-all is automatically added if missing. The catch-all is the part of the path that will remain for the following routes to check against.

### Routes with Blocks instead of Controllers

Routes that respond with a block of code can receive the `request` and `response` objects, allowing for greater usability.

These Routes favor a global response over the different features offered by Controllers (i.e. RESTful routing and virtual folder method routing). Also, the block of code does NOT inherit all the magical abilities bestowed on Controllers which could allow for a slight increase in response time.

Here's a more powerful example of a route with a block of code, thistime using the `request` and `response` passed on to it:

```ruby
require 'plezi'

Plezi.route "/(:id)/(:value)" do |request, response|
   if request.params[:id]
       response.cookies[request.params[:id]] = request.params[:value]
       response << "Set the #{request.params[:id]} cookie to #{request.params[:value] || 'be removed'}.\n\n"
   end
   response << "Your cookies are:\n"
   request.cookies.each {|k, v| response <<  "* #{k}: #{v}\n" }
end

exit
```

## The Controller

(todo: write documentation)

### A Virtual Folder

(todo: write documentation)

### RESTful methods

(todo: write documentation)

### Websocket Callbacks

(todo: write documentation)


