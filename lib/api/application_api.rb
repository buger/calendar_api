module Grape
  module Middleware
    class Base
      module Formats
        CONTENT_TYPES[:ical] = "text/calendar"
        FORMATTERS[:ical] = :encode_ical
        def encode_ical(object)
          object.respond_to?(:to_ical) ? object.to_ical : object.to_s
        end
      end
    end
  end
end

class CalendarAPI < Grape::API
  default_format :json
  error_format :json

  content_type :ical, "text/calendar"

  class LengthLt < Grape::Validations::SingleOptionValidator
    def validate_param!(attr_name, params)
      if params[attr_name].length >= @option
        throw :error, :status => 401, :message => { :errors => 
          { attr_name => ["must be equal or less than #{@option} characters long"] } }
      end    
    end
  end

  helpers do
    def current_user
      @current_user ||= Customer.authorize!(params.api_key)
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_user
    end

    def can?(resource)
      resource && resource.is_accessible?(current_user, params)
    end

    def not_found
      error!({ :error => "Not Found" }, 404)
    end

    def attributes_error(resource)
      error!({ :errors => resource.errors.messages }, 401)
    end
  end

  before do
    authenticate!
  end
end

