class CalendarAPI < Grape::API
  module Entities
    class Calendar < Grape::Entity
      expose :country, :description, :title
      expose :events, :if => { with_events: true }
      expose :holidays, :if => { with_holidays: true }
    end
  end

  resource :calendars do
    get do
      @calendars = current_user.calendars
      present @calendars, with: CalendarAPI::Entities::Calendar,
        with_events: %w(ical html).include?(params.format) ? true : false,
        with_holidays: %w(ical html).include?(params.format) && params.holidays ? true : false
    end

    params do
      requires :title, :length_lt => 40, :type => String
      optional :description, :length_lt => 1000, :type => String
    end
    post do
      calendar = current_user.calendars.build(params.slice(:country, :title, :description))
      if calendar.save
        calendar
      else
        attributes_error(calendar)
      end
    end

    get ":id" do
      @calendar = Calendar.find(params.id)
      if can?(@calendar)
        present @calendar, with: CalendarAPI::Entities::Calendar,
          with_events: %w(ical html).include?(params.format) ? true : false,
          with_holidays: %w(ical html).include?(params.format) && params.holidays ? true : false
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
        if calendar.update_attributes(params.slice(:country, :title, :description))
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

