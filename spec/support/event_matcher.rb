module RSpec
  module CustomMatchers
    class EventMatcher
      def initialize(events)
        @events = events
      end

      def matches?(response)
        @response = format_response(response)
        @response.size == @events.size &&
        @response.zip(@events).all? do |actual_event, expected_event|
          actual_event[:title] == expected_event[:title] &&
          Time.parse(actual_event[:start]) == Time.at(expected_event[:start]).utc.to_s &&
          Time.parse(actual_event[:end]) == Time.at(expected_event[:end]).utc.to_s
        end
      end

      def failure_message_for_should
        "Expected #{@response} to contain #{@events}"
      end

      private

      def format_response(response)
        JSON.parse(response).map(&:symbolize_keys)
      end
    end

    def contain_events(*events)
      EventMatcher.new(events)
    end
  end
end

