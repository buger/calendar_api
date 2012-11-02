module RSpec
  module CustomMatchers
    def response_with_error(status_code, message)
      ErrorMatcher.new(status_code, message, last_response)
    end

    class ErrorMatcher
      def initialize(status_code, error_message, last_response)
        @status_code = status_code
        @error_message = { :error => error_message }.to_json
        @last_response = last_response
      end

      def failure_message_for_should
        "Expected #{@last_response.body} with code #{@last_response.status} 
         to contain an error #{@error_message} with code #{@status_code}"
      end

      def failure_message_for_should_not
        "Expected #{@last_response.body} with code #{@last_response.status} 
         to not contain an error #{@error_message} with code #{@status_code}"
      end

      def matches?(subject)
        @last_response.status == @status_code &&
        @last_response.body == @error_message
      end
    end
  end
end

