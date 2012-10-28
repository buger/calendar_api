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
      if calendar = Calendar.find(params[:id])
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
          requires :start, :type => Integer
          requires :end, :type => Integer
          optional :description, :length_lt => 1000, :type => String
          optional :color, :length_lt => 40, :type => String
        end
        post do
          if calendar = Calendar.find(params[:calendar_ids])
            event = calendar.events.build(params.slice(:title, :description, :start, :end, :color))
            if event.save
              event
            else
              error!({ :errors => event.errors.messages }, 401)
            end
          else
            error!({ :errors => "Not Found" }, 404)
          end
        end
      end
    end
  end
end

