module Plezi
  module Base
    class Err404Ctrl
      def index
        response.status = 404
        render('404') || 'Error 404, not found.'
      end

      def requested_method
        :index
      end

      include Plezi::Controller
    end
    class Err500Ctrl
      def index
        response.status = 500
        render('500') || 'Internal Error 500.'
      rescue
        'Internal Error 500.'
      end

      def requested_method
        :index
      end
      include Plezi::Controller
    end
  end
end
