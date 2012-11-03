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
        attributes_error(calendar)
      end
    end

    get ":id" do
      calendar = Calendar.find(params.id)
      if can?(calendar)
        if params.format == "ical"
          header("Content-Type", "text/calendar")
          IcalendarEvents.new(calendar.events).to_ical
        else
          calendar
        end
      else
        not_found
      end
    end

    params do
      optional :title, :length_lt => 40, :type => String
      optional :description, :length_lt => 1000, :type => String
    end
    put ":id" do
      calendar = Calendar.find(params.id)
      if can?(calendar)
        if calendar.update_attributes(params.slice(:title, :description))
          calendar
        else
          attributes_error(calendar)
        end
      else
        not_found
      end
    end

    delete ":id" do
      calendar = Calendar.find(params.id)
      if can?(calendar)
        calendar.delete
      else
        not_found
      end
    end
  end
end

