require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  let(:customer) { create(:customer) }
  let(:api_key) { { api_key: customer.api_key }.to_query }

  describe "GET /calendars/:ids/events" do
    let(:calendar1) { create(:calendar, customer: customer) }
    let(:calendar2) { create(:calendar, customer: customer) }
    let(:calendar3) { create(:calendar, customer: customer) }

    let!(:event1) { create(:event, calendar: calendar1, start: 9.days.ago.to_i, end: 5.days.ago.to_i) }
    let!(:event2) { create(:event, calendar: calendar1, start: 6.days.ago.to_i, end: 4.days.ago.to_i) }
    let!(:event3) { create(:event, calendar: calendar2, start: 5.days.ago.to_i, end: 1.days.ago.to_i) }
    let!(:event4) { create(:event, calendar: calendar3, start: 7.days.ago.to_i, end: 3.days.ago.to_i) }

    context ".ical" do
      it "returns the events in .ical format" do
        get "/calendars/#{calendar1.id},#{calendar3.id}/events.ical?#{api_key}"
        should respond_with_events(200, :ical, event1, event2, event4)
      end
    end

    context "without the time filter" do
      it "returns an error message if 'id' is invalid" do
        get "/calendars/1231231232423,1231231232432?#{api_key}"
        should respond_with(404, :json, errors: "Not Found")
      end

      it "returns all the events for a single calendar" do
        get "/calendars/#{calendar1.id}/events?#{api_key}"
        should respond_with_events(200, :json, event1, event2)
      end

      it "returns all the events for multiple calendars" do
        get "/calendars/#{calendar1.id},#{calendar3.id}/events?#{api_key}"
        should respond_with_events(200, :json, event1, event2, event4)
      end
    end

    context "with the time filter" do
      it "returns an error if 'start' is not a number" do
        get "/calendars/#{calendar1.id}/events?#{{start: "abc"}.to_query}&#{api_key}"
        should respond_with(400, :json, error: "invalid parameter: start")
      end
      
      it "returns an error if 'start' is more than 'end'" do
        time_scope = {start: 3.days.ago.to_i, end: 7.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar3.id}/events?#{time_scope}&#{api_key}"
        should respond_with(404, :json, errors: "Not Found")
      end

      it "returns an error if 'end' is not a number" do
        get "/calendars/#{calendar1.id}/events?#{{end: "abc"}.to_query}&#{api_key}"
        should respond_with(400, :json, error: "invalid parameter: end")
      end

      it "returns all the events for a single calendar" do
        time_scope = {start: 6.days.ago.to_i, end: 3.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id}/events?#{time_scope}&#{api_key}"
        should respond_with_events(200, :json, event2)

        time_scope = {start: 7.days.ago.to_i, end: 3.days.ago.to_i}.to_query
        get "calendars/#{calendar3.id}/events?#{time_scope}&#{api_key}"
        should respond_with_events(200, :json, event4)
      end

      it "returns all the events for multiple calendars" do
        time_scope = {start: 7.days.ago.to_i, end: 3.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar3.id}/events?#{time_scope}&#{api_key}"
        should respond_with_events(200, :json, event2, event4)

        time_scope = {start: 5.days.ago.to_i, end: 1.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events?#{time_scope}&#{api_key}"
        should respond_with_events(200, :json, event3)

        time_scope = {start: 9.days.ago.to_i, end: 4.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events?#{time_scope}&#{api_key}"
        should respond_with_events(200, :json, event1, event2)

        time_scope = {start: 9.days.ago.to_i, end: 1.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events?#{time_scope}&#{api_key}"
        should respond_with_events(200, :json, event1, event2, event3, event4)
      end
    end
  end

  describe "POST /calendars/:calendar_id/events" do
    let!(:calendar) { create(:calendar, customer: customer) }
    let(:event_attrs) { attributes_for(:event).slice(:title, :start, :end, :color) }

    it "returns an error if calendar is not found" do
      post "/calendars/1232131/events?#{api_key}", event_attrs
      should respond_with(404, :json, errors: "Not Found")
      Event.count.should == 0
    end

    it "returns an error if 'title' is not provided" do
      post "/calendars/#{calendar.id}/events?#{api_key}", event_attrs.slice(:start, :end, :color)
      should respond_with(400, :json, error: "missing parameter: title")
      Event.count.should == 0
    end

    it "returns an error if 'start' is not provided" do
      post "/calendars/#{calendar.id}/events?#{api_key}", event_attrs.slice(:title, :end, :color)
      should respond_with(400, :json, error: "missing parameter: start")
      Event.count.should == 0
    end

    it "returns an error if 'end' is not provided" do
      post "/calendars/#{calendar.id}/events?#{api_key}", event_attrs.slice(:title, :start, :color)
      should respond_with(400, :json, error: "missing parameter: end")
      Event.count.should == 0
    end

    it "returns an error if 'title' is too long" do
      post "/calendars/#{calendar.id}/events?#{api_key}", event_attrs.merge(title: 'a' * 41)
      should respond_with(401, :json, errors:
        { "title" => ["must be equal or less than 40 characters long"] })
      Event.count.should == 0
    end

    it "returns an error if 'description' is too long" do
      post "/calendars/#{calendar.id}/events?#{api_key}", event_attrs.merge(description: 'a' * 1001)
      should respond_with(401, :json, errors:
        { "description" => ["must be equal or less than 1000 characters long"] })
      Event.count.should == 0
    end

    it "returns an error if 'color' is too long" do
      post "/calendars/#{calendar.id}/events?#{api_key}", event_attrs.merge(color: 'a' * 40)
      should respond_with(401, :json, errors:
        { "color" => ["must be equal or less than 40 characters long"] })
      Event.count.should == 0
    end

    it "creates a new event for given calenar" do
      post "/calendars/#{calendar.id}/events?#{api_key}", event_attrs
      should respond_with(201, :json, Event.last)
    end
  end

  describe "GET /calendars/:calendar_id/events/:id" do
    let!(:calendar) { create(:calendar, customer: customer) }
    let!(:event) { create(:event, calendar: calendar) }
    let!(:event2) { create(:event, calendar: calendar) }

    describe "GET /calendars/:calendar_id/events/:id.ical" do
      it "returns the event in .ical format" do
        get "/calendars/#{calendar.id}/events/#{event.id}.ical?#{api_key}"
        # should respond_with_events(200, :ical, event)
        last_response.status.should == 200
        last_response.header["Content-Type"].should == "text/calendar"
        # TODO: create matchers for single events
        # last_response.body[/^DTEND\:(.+)?$/]
        # DateTime.parse($1.strip).to_i.should == event.dtend.to_i
        # last_response.body[/^DTSTART\:(.+)?$/]
        # DateTime.parse($1.strip).to_i.should == event.dtstart.to_i
      end
    end

    it "returns an error if 'calendar_id is not valid'" do
      get "/calendars/12312312/events/#{event.id}?#{api_key}"
      should respond_with(404, :json, errors: "Not Found")
    end

    it "returns an error if 'id' is not valid" do
      get "/calendars/#{calendar.id}/events/123123123?#{api_key}"
      should respond_with(404, :json, errors: "Not Found")
    end

    it "returns an event" do
      get "/calendars/#{calendar.id}/events/#{event.id}?#{api_key}"
      should respond_with(200, :json, event)
    end
  end

  describe "PUT /calendars/:calendar_id/events/:id" do
    let!(:calendar) { create(:calendar, customer: customer) }
    let!(:origin_attrs) { attributes_for(:event) }
    let!(:new_attrs) { attributes_for(:event) }
    let!(:event) { create(:event, origin_attrs.merge(calendar: calendar)) }

    it "returns an error if 'calendar_id' is not valid" do
      put "/calendars/12312312/events/#{event.id}?#{api_key}"
      should respond_with(404, :json, errors: "Not Found")
    end

    it "returns an error if 'id' is not valid" do
      put "/calendars/#{calendar.id}/events/#{"a"*24}?#{api_key}"
      should respond_with(404, :json, errors: "Not Found")
    end

    it "returns an error if 'title' is blank" do
      put "/calendars/#{calendar.id}/events/#{event.id}?#{api_key}", origin_attrs.merge(title: "")
      should respond_with(401, :json, errors: { "title" => ["can't be blank",
        "is too short (minimum is 1 characters)"] })
      event.reload
      event.title.should == origin_attrs[:title]
      event.description.should == origin_attrs[:description]
    end

    it "returns an error if 'title' is too long" do
      put "/calendars/#{calendar.id}/events/#{event.id}?#{api_key}", origin_attrs.merge(title: "a"*41)
      should respond_with(401, :json, errors:
         { "title" => ["must be equal or less than 40 characters long"] })
      event.reload
      event.title.should == origin_attrs[:title]
      event.description.should == origin_attrs[:description]
    end

    it "updates the event" do
      put "/calendars/#{calendar.id}/events/#{event.id}?#{api_key}", new_attrs
      should respond_with(200, :json, Event.last)
      event.reload
      event.title.should == new_attrs[:title]
      event.description.should == new_attrs[:description]
    end

    it "doesn't allow to update 'calendar_id'" do
      put "/calendars/#{calendar.id}/events/#{event.id}?#{api_key}", new_attrs.merge!(calendar_id: "123")
      last_response.status.should == 200
      event.reload
      event.calendar_id.should_not == new_attrs[:calendar_id]
    end

    it "doesn't allow to update 'id'" do
      put "/calendars/#{calendar.id}/events/#{event.id}?#{api_key}", new_attrs.merge!(id: "123")
      last_response.status.should == 200
      event.reload
      event.calendar_id.should_not == new_attrs[:id]
    end
  end

  describe "DELETE /calendars/:calendar_id/events/:id" do
    let!(:calendar) { create(:calendar, customer: customer) }
    let!(:event) { create(:event, calendar: calendar) }

    it "returns an error if 'calendar_id' is not valid" do
      delete "/calendars/12312312/events/#{event.id}?#{api_key}"
      should respond_with(404, :json, errors: "Not Found")
      Event.count.should == 1
    end

    it "returns an error if 'id' is not valid" do
      delete "/calendars/#{calendar.id}/events/#{"a"*24}?#{api_key}"
      should respond_with(404, :json, errors: "Not Found")
      Event.count.should == 1
    end

    it "destroys the event" do
      delete "/calendars/#{calendar.id}/events/#{event.id}?#{api_key}"
      last_response.status.should == 200
      Event.count.should == 0
    end
  end
end

