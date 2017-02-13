require 'test_helper'
require 'stringio'

# a stub routing object for tests
class Stub
   def index
      self.class.last_call = requested_method
   end

   def show
      self.class.last_call = requested_method
   end

   def new
      self.class.last_call = requested_method
   end

   def create
      self.class.last_call = requested_method
   end

   def update
      self.class.last_call = requested_method
   end

   def delete
      self.class.last_call = requested_method
   end

   class << self
     attr_accessor :last_call
   end
end

class RouteTest < Minitest::Test
   def test_it_sets_a_route
      Plezi.no_autostart
      route = Plezi.route('/here/:goes/(:the)/(:manchkin)', Stub).last
      assert route.match('/here/goes/lenny/bruce/1')
   end

   def test_it_maps_function
      Plezi.no_autostart
      route = Plezi.route('/here/:goes/(:the)/(:manchkin)', Stub).last
      assert route.match('/here/goes/lenny/bruce/1')
   end

   def test_it_maps_correct_param_names
      Plezi.no_autostart
      route = Plezi.route('/here/:go[home]/(:go[left])', Stub).last
      assert route.match('/here/Boston/hand/1')
      params = Thread.current["Route#{route.object_id.to_s(16)}".to_sym]
      assert (params == { 'id' => '1', 'go' => { 'home' => 'Boston', 'left' => 'hand' } }), params.to_s
   end

   def test_it_maps_reminder
      Plezi.no_autostart
      route = Plezi.route('/here/*', Stub).last
      assert(route.match('/here/Boston/hand/1'), 'route\'s * tail refused')
      params = Thread.current["Route#{route.object_id.to_s(16)}".to_sym]
      assert((params && params['*'.freeze] && params['*'.freeze].join('/') == 'Boston/hand/1'), "params == #{params.inspect}")
   end

   def test_it_maps_to_rest
      Plezi.no_autostart
      response = Rack::Response.new

      env = { 'PATH_INFO' => '/resource', 'REQUEST_METHOD' => 'GET', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      route = Plezi.route('/resource', Stub).last
      request = Rack::Request.new(env)
      route.call(request, response)
      assert (Stub.last_call == :index), "REST :index wasn't mapped correctly #{Stub.last_call}"

      env = { 'PATH_INFO' => '/resource/1', 'REQUEST_METHOD' => 'GET', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      request = Rack::Request.new(env)
      route.call(request, response)
      assert (Stub.last_call == :show), "REST :show wasn't mapped correctly #{Stub.last_call}"

      env = { 'PATH_INFO' => '/resource/new', 'REQUEST_METHOD' => 'GET', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      request = Rack::Request.new(env)
      route.call(request, response)
      assert (Stub.last_call == :new), "REST :new wasn't mapped correctly #{Stub.last_call}"

      env = { 'PATH_INFO' => '/resource', 'REQUEST_METHOD' => 'POST', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      request = Rack::Request.new(env)
      route.call(request, response)
      assert Stub.last_call == :create, "REST :create wasn't mapped correctly #{Stub.last_call}"

      env = { 'PATH_INFO' => '/resource', 'REQUEST_METHOD' => 'PUT', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      request = Rack::Request.new(env)
      route.call(request, response)
      assert Stub.last_call == :create, "REST :create wasn't mapped correctly #{Stub.last_call}"

      env = { 'PATH_INFO' => '/resource/1', 'REQUEST_METHOD' => 'PUT', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      request = Rack::Request.new(env)
      route.call(request, response)
      assert Stub.last_call == :update, "REST :update wasn't mapped correctly #{Stub.last_call}"

      env = { 'PATH_INFO' => '/resource/1', 'REQUEST_METHOD' => 'PATCH', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      request = Rack::Request.new(env)
      route.call(request, response)
      assert Stub.last_call == :update, "REST :update wasn't mapped correctly #{Stub.last_call}"

      env = { 'PATH_INFO' => '/resource/1', 'REQUEST_METHOD' => 'DELETE', 'QUERY' => '', 'rack.input' => StringIO.new('') }
      request = Rack::Request.new(env)
      route.call(request, response)
      assert Stub.last_call == :delete, "REST :delete wasn't mapped correctly #{Stub.last_call}"
   end
end
