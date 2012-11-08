require "json_spec"
require "differ"

module RSpec
  module CustomMatchers
    CONTENT_TYPES = {
      :json => "application/json",
      :ical => "text/calendar"
    }

    def respond_with(status_code, expected_format, objects)
      ResponseMatcher.new(status_code, last_response, expected_format, objects)
    end

    def respond_with_calendars(status_code, expected_format, *objects)
      ResponseMatcher.new(status_code, last_response, expected_format, objects)
    end

    def respond_with_events(status_code, expected_format, *objects)
      ResponseMatcher.new(status_code, last_response, expected_format, objects)
    end

    def contain_objects(format, *objects)
      ObjectMatcher.new(format, objects)
    end

    class ObjectMatcher
      def initialize(format, objects)
        @formatter = Formatter.new(format)

        @expected = objects
      end

      def matches?(actual)
        @expected = @formatter.format_expected(@expected)
        @actual   = @formatter.format_actual(actual)

        @expected == @actual
      end

      def failure_message_for_should
        "Expected equivalent response: \n" + message
      end

      def failure_message_for_should_not
        "Expected inequivalent response: \n" + message
      end

      private

      def message
        @expected.join("\n") + 
        "\nActual: \n" +
        @actual.join("\n")
      end
    end

    class Formatter
      def initialize(format)
        @formatter = send("#{format}_formatter")
      end

      delegate :format_expected, to: :@formatter
      delegate :format_actual,   to: :@formatter

      def json_formatter
        JsonFormatter.new
      end

      def ical_formatter
        IcalFormatter.new
      end

      class JsonFormatter
        include JsonSpec::Helpers

        def format_expected(json)
          format parse_json(json.to_json)
        end
        
        def format_actual(json)
          format parse_json(json)
        end

        private

        def format(json)
          generate_normalized_json(sort_json(normalize_time(json))).chomp + "\n"
        end

        def sort_json(json)
          Array === json ? json.sort_by { |h| h[:zip] } : json
        end

        def normalize_time(json)
          return json unless Array === json

          json.map do |hash| 
            hash.map do |k, v| 
              { k => (["dtend","dtstart"].include?(k) ? DateTime.parse(v) : v) }
            end.reduce(:merge)
          end
        end
      end

      class IcalFormatter
        def format_expected(ical)
          ical.map do |event|
            [event.title, normalize_time(event.dtstart), normalize_time(event.dtend)].inspect
          end
        end
        
        def format_actual(ical)
          Icalendar.parse(ical).first.events.map do |event|
            [event.summary, event.dtstart, event.dtend].inspect
          end
        end

        private

        def normalize_time(time)
          DateTime.parse(time.utc.to_s)
        end
      end
    end

    class ResponseMatcher
      def initialize(status_code, response, expected_format, objects)
        @formatter = Formatter.new(expected_format)

        @expected_content_type = CONTENT_TYPES[expected_format] || expected_format
        @actual_content_type   = response.content_type

        @expected_status_code = status_code
        @actual_status_code   = response.status

        @expected_body = @formatter.format_expected(objects)
        @actual_body   = @formatter.format_actual(response.body)
      end

      def matches?(*)
        status_codes && content_types && bodies
      end

      def failure_message_for_should
        "Expected equivalent response: \n" + message
      end

      def failure_message_for_should_not
        "Expected inequivalent response: \n" + message
      end

      private

      def message
        "Status Code: #{@expected_status_code}\n" +
        "Content Type: #{@expected_content_type}\n" +
        "Body: \n #{@expected_body}\n" +
        "Actual: \n" +
        "Status Code: #{@actual_status_code}\n" +
        "Content Type: #{@actual_content_type}\n" +
        "Body: \n #{@actual_body}\n"
      end

      def status_codes
        @expected_status_code == @actual_status_code
      end

      def content_types
        @expected_content_type == @actual_content_type
      end

      def bodies
        @expected_body == @actual_body
      end
    end
  end
end

