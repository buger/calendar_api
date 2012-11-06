module RSpec
  module CustomMatchers
    module IcalMatcher
      def failure_message_for_should
        message
      end

      def failure_message_for_should_not
        message
      end

      private

      def message
        "Expected: \n#{@parsed_expected_events.join("\n")}\n" +
        "Actual:   \n#{@parsed_actual_events.join("\n")}\n"
      end

      def parse_expected_events(events)
        events.map do |event|
          [event.title, DateTime.parse(event.start.utc.to_s), DateTime.parse(event.end.utc.to_s)].inspect
        end
      end

      def parse_actual_events(response_body)
        parse_ical(response_body).map do |event|
          [event.summary, event.dtstart, event.dtend].inspect
        end
      end

      def parse_ical(events_in_ical)
        Icalendar.parse(events_in_ical).first.events
      end
    end
  end
end

