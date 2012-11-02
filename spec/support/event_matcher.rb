module RSpec
  module CustomMatchers
    def contain_events(*events)
      if events.empty?
        raise ArgumentError, "need at least one argument"
      else
        EventMatcher.new(events)
      end
    end

    class EventMatcher
      def initialize(events)
        @events = events
      end

      def failure_message_for_should
        "Expected #{@response_body} to contain #{@events}"
      end

      def failure_message_for_should_not
        "Expected #{@response_body} to not contain #{@events}"
      end

      def matches?(response_body)
        @response_body = parse_json(response_body)
        @events.size == @response_body.size &&
        @response_body.zip(@events).all? do |actual_event, expected_event|
          actual_event.keys.sort == expected_event.keys.sort &&
          actual_event[:title] == expected_event[:title] &&
          Time.parse(actual_event[:start]) == Time.at(expected_event[:start]).utc.to_s &&
          Time.parse(actual_event[:end]) == Time.at(expected_event[:end]).utc.to_s
        end
      end

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

