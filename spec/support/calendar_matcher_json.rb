module RSpec
  module CustomMatchers
    def contain_calendars_in_json(*calendars)
      if calendars.empty?
        raise ArgumentError, "need at least one argument"
      else
        CalendarMatcherJson.new(calendars)
      end
    end

    class CalendarMatcherJson < BaseMatcherJson
      def initialize(calendars)
        @calendars = calendars
      end

      def failure_message_for_should
        "Expected #{@response_body} to contain #{@calendars}"
      end

      def failure_message_for_should_not
        "Expected #{@response_body} to not contain #{@calendars}"
      end

      def matches?(response_body)
        @calendars.sort_by { |x| x[:country] } == 
        parse_json(response_body).sort_by { |x| x[:country] }
      end
    end
  end
end

