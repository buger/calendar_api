module RSpec
  module CustomMatchers
    module ResponseMatcher
      private

      def returns_json?(response)
        successful_status(response) && json?(response)
      end

      def returns_ical?(response)
        successful_status(response) && ical?(response)
      end

      def successful_status(response)
        response.status == 200 || response.status == 201
      end

      def json?(response)
        response.header["Content-Type"] == "application/json"
      end

      def ical?(response)
        response.header["Content-Type"] == "text/calendar"
      end
    end
  end
end

