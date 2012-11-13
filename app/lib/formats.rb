module Grape
  module Middleware
    class Base
      module Formats
        CONTENT_TYPES[:ical] = "text/calendar"
        CONTENT_TYPES[:html] = "text/html"

        FORMATTERS[:ical]    = :encode_ical
        FORMATTERS[:html]    = :encode_html

        def encode_ical(object)
          IcalRender.new(object).render
        end

        def encode_html(object)
          HTMLRender.new(object).render
        end
      end
    end
  end
end

