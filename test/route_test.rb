require 'test_helper'

class Stub
end

class RouteTest < Minitest::Test
  def test_it_sets_a_route
    Plezi.no_autostart
    route = Plezi.route('/here/:goes/(:the)/(:manchkin)', Stub).last
    assert route.match('/here/goes/lenny/bruce/1')
  end
end
