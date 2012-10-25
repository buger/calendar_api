class CalendarAPI < Grape::API
  class LengthLt < Grape::Validations::SingleOptionValidator
    def validate_param!(attr_name, params)
      if params[attr_name].length >= @option
        throw :error, :status => 401, :message => { :errors => 
          { attr_name => ["must be equal or less than #{@option} characters long"] } }
      end    
    end
  end

  module Helpers
    def extract(hash, *attrs)
      result = {}
      attrs.each { |key| result[key] = hash[key] if hash[key] }
      result
    end
  end

  helpers do
    include Helpers
  end

  format :json

  resource :calendars do
    get do
      Calendar.all.to_json(:only => ["title", "description"])
    end

    params do
      requires :title, :length_lt => 40, :type => String
      requires :description, :length_lt => 1000, :type => String
    end
    post do
      calendar = Calendar.new(extract(params, :title, :description))
      if calendar.save
        calendar.to_json(:only => ["title", "description"])
      else
        error!({ :errors => calendar.errors.messages }, 401)
      end
    end

    get ":id" do
      if calendar = Calendar.find(params[:id])
        calendar.to_json(:only => ["title", "description"])
      else
        error!({ :errors => "Not Found" }, 404)
      end
    end

    put ":id" do
      if calendar = Calendar.find(params[:id])
        if calendar.update_attributes(extract(params, :title, :description))
          calendar.to_json(:only => ["title", "description"])
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

    segment "/:calendar_id" do
      resource :events do
        get {  }
      end
    end
  end
end

