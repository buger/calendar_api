require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe "GET /calendars/:ids/events" do
    let(:calendar1) { create(:calendar) }
    let(:calendar2) { create(:calendar) }
    let(:calendar3) { create(:calendar) }

    let(:event_attrs1) { attributes_for(:event, start: 9.days.ago.to_i, end: 5.days.ago.to_i) }
    let(:event_attrs2) { attributes_for(:event, start: 6.days.ago.to_i, end: 4.days.ago.to_i) }
    let(:event_attrs3) { attributes_for(:event, start: 5.days.ago.to_i, end: 1.days.ago.to_i) }
    let(:event_attrs4) { attributes_for(:event, start: 7.days.ago.to_i, end: 3.days.ago.to_i) }

    let!(:event1) { create(:event, event_attrs1.merge(:calendar => calendar1)) }
    let!(:event2) { create(:event, event_attrs2.merge(:calendar => calendar1)) }
    let!(:event3) { create(:event, event_attrs3.merge(:calendar => calendar2)) }
    let!(:event4) { create(:event, event_attrs4.merge(:calendar => calendar3)) }

    context "without the time filter" do
      it "returns an error message if 'id' is invalid" do
        get "/calendars/1231231232423,1231231232432"
        last_response.status.should == 404
        last_response.body.should == { :errors => "Not Found" }.to_json
      end

      it "returns all the events for a single calendar" do
        get "/calendars/#{calendar1.id}/events"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs1, event_attrs2)
      end

      it "returns all the events for multiple calendars" do
        get "/calendars/#{calendar1.id},#{calendar3.id}/events"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs1, event_attrs2, event_attrs4)
      end
    end

    context "with the time filter" do
      it "returns an error if 'start' is not a number" do
        get "/calendars/#{calendar1.id}/events?#{{:start => "abc"}.to_query}"
        last_response.status.should == 400
        last_response.body.should == { :error => "invalid parameter: start" }.to_json
      end
      
      it "returns an error if 'start' is more than 'end'" do
        time_scope = {:start => 3.days.ago.to_i, :end => 7.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar3.id}/events?#{time_scope}"
        last_response.status.should == 404
        last_response.body.should == { :errors => "Not Found" }.to_json
      end

      it "returns an error if 'end' is not a number" do
        get "/calendars/#{calendar1.id}/events?#{{:end => "abc"}.to_query}"
        last_response.status.should == 400
        last_response.body.should == { :error => "invalid parameter: end" }.to_json
      end

      it "returns all the events for a single calendar" do
        time_scope = {:start => 6.days.ago.to_i, :end => 3.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id}/events?#{time_scope}"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs2)

        time_scope = {:start => 7.days.ago.to_i, :end => 3.days.ago.to_i}.to_query
        get "calendars/#{calendar3.id}/events?#{time_scope}"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs4)

        time_scope = {:start => 7.days.ago.to_i, :end => 3.days.ago.to_i}.to_query
        get "calendars/#{calendar3.id}/events?#{time_scope}"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs4)
      end

      it "returns all the events for multiple calendars" do
        time_scope = {:start => 7.days.ago.to_i, :end => 3.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar3.id}/events?#{time_scope}"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs2, event_attrs4)

        time_scope = {:start => 5.days.ago.to_i, :end => 1.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events?#{time_scope}"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs3)

        time_scope = {:start => 9.days.ago.to_i, :end => 4.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events?#{time_scope}"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs1, event_attrs2)

        time_scope = {:start => 9.days.ago.to_i, :end => 1.days.ago.to_i}.to_query
        get "calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events?#{time_scope}"
        last_response.status.should == 200
        last_response.body.should contain_events(event_attrs1, event_attrs2, event_attrs3, event_attrs4)
      end
    end
  end

  describe "POST /calendars/:calendar_id/events" do
    let!(:calendar) { create(:calendar) }
    let(:event_attrs) { attributes_for(:event).slice(:title, :start, :end, :color) }

    it "returns an error if calendar is not found" do
      post "/calendars/1232131/events", event_attrs
      last_response.status.should == 404
      last_response.body.should == { :errors => "Not Found" }.to_json
      Event.count.should == 0
    end

    it "returns an error if 'title' is not provided" do
      post "/calendars/#{calendar.id}/events", event_attrs.slice(:start, :end, :color)
      last_response.status.should == 400
      last_response.body.should == { :error => "missing parameter: title" }.to_json
      Event.count.should == 0
    end

    it "returns an error if 'start' is not provided" do
      post "/calendars/#{calendar.id}/events", event_attrs.slice(:title, :end, :color)
      last_response.status.should == 400
      last_response.body.should == { :error => "missing parameter: start" }.to_json
      Event.count.should == 0
    end

    it "returns an error if 'end' is not provided" do
      post "/calendars/#{calendar.id}/events", event_attrs.slice(:title, :start, :color)
      last_response.status.should == 400
      last_response.body.should == { :error => "missing parameter: end" }.to_json
      Event.count.should == 0
    end

    it "returns an error if 'title' is too long" do
      post "/calendars/#{calendar.id}/events", event_attrs.merge(:title => 'a' * 41)
      last_response.status.should == 401
      last_response.body.should == { :errors => 
        { "title" => ["must be equal or less than 40 characters long"] } }.to_json
      Event.count.should == 0
    end

    it "returns an error if 'description' is too long" do
      post "/calendars/#{calendar.id}/events", event_attrs.merge(:description => 'a' * 1001)
      last_response.status.should == 401
      last_response.body.should == { :errors => 
        { "description" => ["must be equal or less than 1000 characters long"] } }.to_json
      Event.count.should == 0
    end

    it "returns an error if 'color' is too long" do
      post "/calendars/#{calendar.id}/events", event_attrs.merge(:color => 'a' * 40)
      last_response.status.should == 401
      last_response.body.should == { :errors => 
        { "color" => ["must be equal or less than 40 characters long"] } }.to_json
      Event.count.should == 0
    end

    it "creates a new event for given calenar" do
      post "/calendars/#{calendar.id}/events", event_attrs
      last_response.status.should == 201
      last_response.body.should contain_events(event_attrs)
      Event.last.title.should == event_attrs[:title]
    end
  end

  describe "GET /calendars/:calendar_id/events/:id" do
    let!(:calendar) { create(:calendar) }
    let!(:event_attrs) { attributes_for(:event) }
    let!(:event) { create(:event, event_attrs.merge(:calendar => calendar)) }

    it "returns an error if 'calendar_id is not valid'" do
      get "/calendars/12312312/events/#{event.id}"
      last_response.status.should == 404
      last_response.body.should == { :errors => "Not Found" }.to_json
    end

    it "returns an error if 'id' is not valid" do
      get "/calendars/#{calendar.id}/events/123123123"
      last_response.status.should == 404
      last_response.body.should == { :errors => "Not Found" }.to_json
    end

    it "returns an event" do
      get "/calendars/#{calendar.id}/events/#{event.id}"
      last_response.status.should == 200
      last_response.body.should contain_events(event_attrs)
    end
  end

  describe "PUT /calendars/:calendar_id/events/:id" do
    let!(:calendar) { create(:calendar) }
    let!(:origin_attrs) { attributes_for(:event) }
    let!(:new_attrs) { attributes_for(:event) }
    let!(:event) { create(:event, origin_attrs.merge(:calendar => calendar)) }

    it "returns an error if 'calendar_id' is not valid" do
      put "/calendars/12312312/events/#{event.id}"
      last_response.status.should == 404
      last_response.body.should == { :errors => "Not Found" }.to_json
    end

    it "returns an error if 'id' has wrong format" do
      put "/calendars/#{calendar.id}/events/#{"a"*23}"
      last_response.status.should == 400
      last_response.body.should == { :error => "invalid parameter: id" }.to_json
    end

    it "returns an error if 'id' is not valid" do
      put "/calendars/#{calendar.id}/events/#{"a"*24}"
      last_response.status.should == 404
      last_response.body.should == { :errors => "Not Found" }.to_json
    end

    it "returns an error if 'title' is blank" do
      put "/calendars/#{calendar.id}/events/#{event.id}", origin_attrs.merge(:title => "")
      last_response.status.should == 401
      last_response.body.should == { :errors => { "title" => ["can't be blank"] } }.to_json
      event.reload
      event.title.should == origin_attrs[:title]
      event.description.should == origin_attrs[:description]
    end

    it "returns an error if 'title' is too long" do
      put "/calendars/#{calendar.id}/events/#{event.id}", origin_attrs.merge(:title => "a"*41)
      last_response.status.should == 401
      last_response.body.should == { :errors => 
         { "title" => ["must be equal or less than 40 characters long"] } }.to_json
      event.reload
      event.title.should == origin_attrs[:title]
      event.description.should == origin_attrs[:description]
    end

    it "updates the event" do
      put "/calendars/#{calendar.id}/events/#{event.id}", new_attrs
      last_response.status.should == 200
      last_response.body.should contain_events(new_attrs)
      event.reload
      event.title.should == new_attrs[:title]
      event.description.should == new_attrs[:description]
    end

    it "doesn't allow to update 'calendar_id'" do
      put "/calendars/#{calendar.id}/events/#{event.id}", new_attrs.merge!(:calendar_id => "123")
      last_response.status.should == 200
      event.reload
      event.calendar_id.should_not == new_attrs[:calendar_id]
    end

    it "doesn't allow to update 'id'" do
      put "/calendars/#{calendar.id}/events/#{event.id}", new_attrs.merge!(:id => "123")
      last_response.status.should == 200
      event.reload
      event.calendar_id.should_not == new_attrs[:id]
    end
  end

  describe "DELETE /calendars/:calendar_id/events/:id" do
    let!(:calendar) { create(:calendar) }
    let!(:event) { create(:event, :calendar => calendar) }

    it "returns an error if 'calendar_id' is not valid" do
      delete "/calendars/12312312/events/#{event.id}"
      last_response.status.should == 404
      last_response.body.should == { :errors => "Not Found" }.to_json
      Event.count.should == 1
    end

    it "returns an error if 'id' has wrong format" do
      delete "/calendars/#{calendar.id}/events/#{"a"*23}"
      last_response.status.should == 400
      last_response.body.should == { :error => "invalid parameter: id" }.to_json
      Event.count.should == 1
    end

    it "returns an error if 'id' is not valid" do
      delete "/calendars/#{calendar.id}/events/#{"a"*24}"
      last_response.status.should == 404
      last_response.body.should == { :errors => "Not Found" }.to_json
      Event.count.should == 1
    end

    it "destroys the event" do
      delete "/calendars/#{calendar.id}/events/#{event.id}"
      last_response.status.should == 200
      Event.count.should == 0
    end
  end
end
