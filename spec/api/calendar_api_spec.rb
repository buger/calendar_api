require "spec_helper.rb"
require "icalendar"

describe CalendarAPI do
  include Rack::Test::Methods
  include RSpec::AuthHelpher

  def app
    CalendarAPI
  end

  let(:customer) { create(:customer) }
  let(:api_key) { { api_key: customer.api_key }.to_query }

  describe "GET /calendars" do
    let!(:calendar1) { create(:calendar, customer: customer) }
    let!(:calendar2) { create(:calendar, customer: customer) }
    let!(:event1) { create(:event, calendar: calendar1) }
    let!(:event2) { create(:event, calendar: calendar2) }
    let!(:event3) { create(:event, calendar: calendar2) }

    context "JSON" do
      it "returns all the calendars" do
        get "/calendars"
        should respond_with_calendars(200, :json, calendar1, calendar2)
      end
    end

    context "ICAL" do
      it "return all the events of the calendars in ical file" do
        get "/calendars.ical"
        should respond_with_calendars(200, :ical, event1, event2, event3)
      end
    end
    
    context "HTML" do
      it "return all the events of the calendars in html file" do
        get "/calendars.html"
        last_response.status.should == 200
        last_response.content_type.should == "text/html"
      end
    end
  end

  describe "POST /calendars" do
    let(:params) { attributes_for(:calendar, id: 123, customer_id: 124) }

    context "when parameters are valid" do
      it "creates a new calendar" do
        post "/calendars", params
        should respond_with(201, :json, params.slice(:country, :description, :title))
        Calendar.count.should == 1
        Calendar.last.customer_id.should_not == params[:customer_id]
        Calendar.last.id.should_not == params[:id]
        Calendar.last.customer_id.should == customer.id
      end
    end

    context "when parameters are invalid" do
      it "returns error messages from api and molde layers" do
        post "calendars", params.merge(title: "")
        should respond_with(401, :json, errors: { "title" => ["can't be blank",
        "is too short (minimum is 1 characters)"] })
        Calendar.count.should == 0
      end
    end
  end

  describe "GET /calendars/:id" do
    let(:params) { attributes_for(:calendar, description: "q") }
    let(:calendar) { create(:calendar, params.merge(customer: customer)) }
    let(:calendar2) { create(:calendar, params.merge(customer: customer)) }

    it "returns the calendar" do
      get "/calendars/#{calendar.id}"
      should respond_with(200, :json, params.slice(:country, :description, :title))
    end

    it "returns an error if 'id' is invalid" do
      get "/calendars/1234124234"
      should respond_with(404, :json, errors: "Not Found")
    end

    context ".ical" do
      let!(:event_1) { create(:event, calendar: calendar,  start: 9.days.ago, end: 5.days.ago) }
      let!(:event_2) { create(:event, calendar: calendar,  start: 6.days.ago, end: 3.days.ago) }
      let!(:event_3) { create(:event, calendar: calendar2, start: 7.days.ago, end: 1.days.ago) }

      it "returns the calendar in .ical format" do
        get "/calendars/#{calendar.id}.ical"
        should respond_with_events(200, :ical, *calendar.events)
      end
    end
  end
  
  describe "PUT /calendars/:id" do
    let(:origin_params) { attributes_for(:calendar) }
    let(:new_params) { attributes_for(:calendar, :description => "q") }
    let(:calendar) { create(:calendar, origin_params.merge(:customer => customer)) }

    context "when parameters are valid" do
      it "updates the object" do
        put "/calendars/#{calendar.id}", new_params
        last_response.status.should == 200
        last_response.body.should == new_params.slice(:country, :description, :title).to_json

        calendar.reload
        calendar.title.should == new_params[:title]
        calendar.description.should == new_params[:description]
      end
    end

    context "when parameters are invalid" do
      it "returns an error if 'id' if invalid" do
        put "/calendars/123213123", new_params
        should respond_with(404, :json, errors: "Not Found")
      end

      it "returns error messages from api and molde layers" do
        put "/calendars/#{calendar.id}", new_params.merge(:title => "")
        should respond_with(401, :json, errors: { "title" => ["can't be blank",
          "is too short (minimum is 1 characters)"] })
        calendar.reload
        calendar.title.should == origin_params[:title]
        calendar.description.should == origin_params[:description]
      end
    end
  end

  describe "DELETE /calendars/:id" do
    let!(:calendar) { create(:calendar, :customer => customer) }

    it "removes the calendar" do
      delete "/calendars/#{calendar.id}"
      last_response.status.should == 200
      Calendar.find(calendar.id).should == nil
    end

    it "returns an error if 'id' is invalid" do
      delete "/calendars/21312312312"
      should respond_with(404, :json, errors: "Not Found")
    end
  end
end

