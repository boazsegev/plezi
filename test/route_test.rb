require 'test_helper'

class Stub
  def index
    'Hello test'
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
end
