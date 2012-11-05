module RSpec
  module CustomMatchers
    class BaseMatcherJson
      private

      def parse_json(response_body)
        json_object = ActiveSupport::JSON.decode(response_body)
        case json_object
        when Hash
          [Hash[json_object.sort].symbolize_keys]
        when Array
          json_object.map(&:symbolize_keys)
        else 
          json_object
        end
      end
    end
  end
end

