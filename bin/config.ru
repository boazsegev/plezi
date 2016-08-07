require 'benchmark'

require 'plezi'
# our Plezi application
class MyCtrl
  def index
    'Hello from Plezi!'
  end
end
# rewites
Plezi.route '(:format)', /^(json|html)$/
# Our Plezi route
Plezi.route 'plezi/*', MyCtrl
# The Rack application
app = proc { |env| req = Rack::Request.new(env); str = "Params: #{req.params}"; [200, { 'Content-Length' => str.bytesize.to_s }, [str]] }
# Use Plezi as Middleware
use Plezi
# run our Rack application
run app

# ab -n 1000000 -c 2000 -k http://127.0.0.1:3000/
# wrk -c400 -d5 -t12 http://localhost:3000/
