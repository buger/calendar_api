module RSpec
  module CustomMatchers
    def respond_with_calendar_in_ical(calendar)
      ResponseCalendarMatcherIcal.new(calendar, last_response)
    end

    class ResponseCalendarMatcherIcal
      include ResponseMatcher
      include IcalMatcher

      def initialize(expected_calendar, response)
        @expected_calendar = expected_calendar
        @response = response
      end

      def matches?(subject)
        @parsed_expected_events = parse_expected_events(@expected_calendar.events)
        @parsed_actual_events   = parse_actual_events(@response.body)

        returns_ical?(@response) && @parsed_expected_events == @parsed_actual_events
      end
    end
  end
end

