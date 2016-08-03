module Plezi
  module Base
    class Err404Ctrl
      def index
        puts '404 not found response'
        response.status = 404
        render('404') || 'Error 404, not found.'
      end
      include Plezi::Base::Controller
    end
    class Err500Ctrl
      def index
        response.status = 500
        render('500') || 'Internal Error 500.'
      rescue
        'Internal Error 500.'
      end
      include Plezi::Base::Controller
    end
  end
end
