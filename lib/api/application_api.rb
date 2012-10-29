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
    def location_for(resource)
      File.join @env["PATH_INFO"], resource.id
    end
  end
end

