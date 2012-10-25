class CalendarAPI < Grape::API
  format :json

  resource :calendars do
    get do
    end

    segment "/:calendar_id" do
      resource :events do
        get {  }
      end
    end
  end
end

