class CalendarAPI < Grape::API
  format :json
  error_format :json

  resource :calendars do
    get do
      Calendar.all
    end

    params do
      requires :title, :length_lt => 40, :type => String
      optional :description, :length_lt => 1000, :type => String
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
      if calendar = Calendar.find(params.id)
        calendar
      else
        error!({ :errors => "Not Found" }, 404)
      end
    end

    params do
      optional :title, :length_lt => 40, :type => String
      optional :description, :length_lt => 1000, :type => String
    end
    put ":id" do
      if calendar = Calendar.find(params.id)
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
      if calendar = Calendar.find(params.id)
        calendar.delete
      else
        error!({ :errors => "Not Found" }, 404)
      end
    end
  end
end

