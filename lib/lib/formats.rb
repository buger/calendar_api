module Grape
  module Middleware
    class Base
      module Formats
        CONTENT_TYPES[:ical] = "text/calendar"
        FORMATTERS[:ical]    = :encode_ical

        def encode_ical(object)
          object.respond_to?(:to_ical) ? object.to_ical : object.to_s
        end
      end
    end
  end
end
