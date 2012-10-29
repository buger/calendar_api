class CalendarAPI < Grape::API
  resource :calendars do
    namespace "/:calendar_ids" do
      resource :events do
        params do
          optional :start, :type => Integer
          optional :end, :type => Integer
        end
        get do
          events = Event.search(params.slice(:calendar_ids, :start, :end))
          if events.any?
            events.to_json
          else
            error!({ :errors => "Not Found" }, 404)
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
          if calendar = Calendar.find(params.calendar_ids)
            event = calendar.events.build(params.slice(:title, :description, :start, :end, :color))
            if event.save
              header("Location", location_for(event))
              event
            else
              error!({ :errors => event.errors.messages }, 401)
            end
          else
            error!({ :errors => "Not Found" }, 404)
          end
        end

        get ":id" do
          event = Event.find(params.id)
          if event && event.calendar_id.to_s == params.calendar_ids
            event
          else
            error!({ :errors => "Not Found" }, 404)
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
          if event && event.calendar_id.to_s == params.calendar_ids
            if event.update_attributes(params.slice(:title, :description, :start, :end, :color))
              event
            else
              error!({ :errors => event.errors.messages }, 401)
            end
          else
            error!({ :errors => "Not Found" }, 404)
          end
        end

        delete ":id" do
          event = Event.find(params.id)
          if event && event.calendar_id.to_s == params.calendar_ids
            event.delete
          else
            error!({ :errors => "Not Found" }, 404)
          end
        end
      end
    end
  end
end
