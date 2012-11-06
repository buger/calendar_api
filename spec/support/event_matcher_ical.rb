module RSpec
  module CustomMatchers
    def contain_events_in_ical(*events)
      EventMatcherIcal.new(events)
    end

    class EventMatcherIcal
      include ResponseMatcher
      include IcalMatcher

      def initialize(events)
        @expected_events = events.flatten
      end

      def matches?(events_in_ical)
        @parsed_expected_events = parse_expected_events(@expected_events)
        @parsed_actual_events   = parse_actual_events(events_in_ical)

        @parsed_expected_events == @parsed_actual_events
      end
    end
  end
end

