require "active_support/core_ext/hash/slice.rb"

class CalendarAPI < Grape::API
  class LengthLt < Grape::Validations::SingleOptionValidator
    def validate_param!(attr_name, params)
      if params[attr_name].length >= @option
        throw :error, :status => 401, :message => { :errors => 
          { attr_name => ["must be equal or less than #{@option} characters long"] } }
      end    
    end
  end

  format :json

  resource :calendars do
    get do
      Calendar.all
    end

    params do
      requires :title, :length_lt => 40, :type => String
      requires :description, :length_lt => 1000, :type => String
    end
    post do
      calendar = Calendar.new(params.slice(:title, :description))
      if calendar.save
        calendar
      else
        error!({ :errors => calendar.errors.messages }, 401)
      end
    end

    get ":id" do
      if calendar = Calendar.find(params[:id])
        calendar
      else
        error!({ :errors => "Not Found" }, 404)
      end
    end

    params do
      requires :title, :length_lt => 40, :type => String
      requires :description, :length_lt => 1000, :type => String
    end
    put ":id" do
      if calendar = Calendar.find(params[:id])
        if calendar.update_attributes(params.slice(:title, :description))
          calendar
        else
          error!({ :errors => calendar.errors.messages }, 401)
        end
      else
        error!({ :errors => "Not Found" }, 404)
      end
    end

    delete ":id" do
      if calendar = Calendar.find(params[:id])
        calendar.delete
      else
        error!({ :errors => "Not Found" }, 404)
      end
    end

    segment "/:calendar_ids" do
      resource :events do
        get do
        end
      end
    end
  end
end

