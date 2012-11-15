class CalendarAPI < Grape::API
  resource :calendars do
    namespace "/:calendar_ids" do
      resource :events do
        params do
          optional :start, :type => Integer
          optional :end, :type => Integer
        end
        get do
          events = Event.search(params.slice(:calendar_ids, :start, :end), current_user)
          if params.holidays
            events += Event.in(holiday_calendar_id: current_user.calendars.map(&:holiday_calendar_id).uniq).to_a
          end
          if events.any?
            events
          else
            not_found
          end
        end

        params do
          requires :title, :length_lt => 40, :type => String
          optional :description, :length_lt => 1000, :type => String
          optional :color, :length_lt => 40, :type => String
          requires :start, :type => Integer
          requires :end, :type => Integer
        end
        post do
          calendar = Calendar.find(params.calendar_ids)
          if can?(calendar)
            event = calendar.events.build(params.slice(:title, :description, :start, :end, :color))
            if event.save
              event
            else
              attributes_error(event)
            end
          else
            not_found
          end
        end

        get ":id" do
          event = Event.find(params.id)
          if can?(event)
            event
          else
            not_found
          end
        end

        params do
          optional :title, :length_lt => 40, :type => String
          optional :description, :length_lt => 1000, :type => String
          optional :color, :length_lt => 40, :type => String
          optional :start, :type => Integer
          optional :end, :type => Integer
        end
        put ":id" do
          event = Event.find(params.id)
          if can?(event)
            if event.update_attributes(params.slice(:title, :description, :start, :end, :color))
              event
            else
              attributes_error(event)
            end
          else
            not_found
          end
        end

        delete ":id" do
          event = Event.find(params.id)
          if can?(event)
            event.delete
          else
            not_found
          end
        end
      end
    end
  end
end

