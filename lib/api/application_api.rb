class CalendarAPI < Grape::API
  format :json
  error_format :json

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
  end

  before do
    authenticate!
  end
end
