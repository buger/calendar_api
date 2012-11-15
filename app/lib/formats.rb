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
          HTMLRender.new(public_path, object).render
        end

        private

        def public_path
          "./".concat("../" * (request.path.count(?/) - 1))
        end
      end
    end
  end
end

