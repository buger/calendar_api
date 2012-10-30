class CalendarAPI < Grape::API
  resource :calendars do
    get do
      Calendar.for_customer(current_user).all
    end

    params do
      requires :title, :length_lt => 40, :type => String
      optional :description, :length_lt => 1000, :type => String
    end
    post do
      calendar = current_user.calendars.build(params.slice(:title, :description))
      if calendar.save
        calendar
      else
        error!({ :errors => calendar.errors.messages }, 401)
      end
    end

    get ":id" do
      calendar = Calendar.find(params.id)
      if calendar && current_user.has?(calendar)
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
      calendar = Calendar.find(params.id)
      if calendar && current_user.has?(calendar)
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
      calendar = Calendar.find(params.id)
      if calendar && current_user.has?(calendar)
        calendar.delete
      else
        error!({ :errors => "Not Found" }, 404)
      end
    end
  end
end

