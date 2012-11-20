require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  let!(:customer1) { create(:customer) }
  let!(:customer2) { create(:customer) }

  let!(:api_key) { { api_key: customer1.api_key }.to_query }

  let!(:holiday_calendar1) { create(:holiday_calendar) }
  let!(:holiday_calendar2) { create(:holiday_calendar) }

  let!(:holiday1) { create(:event, holiday_calendar: holiday_calendar1) }
  let!(:holiday2) { create(:event, holiday_calendar: holiday_calendar2) }
  let!(:holiday3) { create(:event, holiday_calendar: holiday_calendar2) }

  let!(:calendar1) { create(:calendar, customer: customer1, country: holiday_calendar1.country) }
  let!(:calendar2) { create(:calendar, customer: customer1, country: holiday_calendar2.country) }
  let!(:calendar3) { create(:calendar, customer: customer2) }

  let!(:event1) { create(:event, calendar: calendar1) }
  let!(:event2) { create(:event, calendar: calendar1) }
  let!(:event3) { create(:event, calendar: calendar2) }
  let!(:event4) { create(:event, calendar: calendar2) }
  let!(:event5) { create(:event, calendar: calendar3) }

  describe "GET /calendars.html" do
    it "includes holidays from all calendars" do
      get "/calendars.html?#{api_key}&holidays=true"
      last_response.status.should == 200
      calendar1.events.each   { |e| last_response.body.should include(e.title) }
      calendar1.holidays.each { |e| last_response.body.should include(e.title) }
      calendar2.events.each   { |e| last_response.body.should include(e.title) }
      calendar2.holidays.each { |e| last_response.body.should include(e.title) }
      last_response.body.should include(calendar1.title)
      last_response.body.should include(calendar2.title)
    end

    it "doesn't include holidays from all calendars" do
      get "/calendars.html?#{api_key}"
      last_response.status.should == 200
      calendar1.events.each   { |e| last_response.body.should include(e.title) }
      calendar1.holidays.each { |e| last_response.body.should_not include(e.title) }
      calendar2.events.each   { |e| last_response.body.should include(e.title) }
      calendar2.holidays.each { |e| last_response.body.should_not include(e.title) }
      last_response.body.should include(calendar1.title)
      last_response.body.should include(calendar2.title)
    end
  end

  describe "GET /calendars.ical" do
    it "includes holidays from all calendars" do
      get "/calendars.ical?#{api_key}&holidays=true"
      should respond_with(200, :ical,
        calendar1.events + calendar1.holidays + calendar2.events + calendar2.holidays)
    end

    it "doesn't include holidays" do
      get "/calendars.ical?#{api_key}"
      should respond_with(200, :ical, calendar1.events + calendar2.events)
    end
  end

  describe "GET /calendars/:id.html" do
    it "includes holidays in the result" do
      get "/calendars/#{calendar2.id}.html?#{api_key}&holidays=true"
      last_response.status.should == 200
      calendar2.events.each   { |e| last_response.body.should include(e.title) }
      calendar2.holidays.each { |e| last_response.body.should include(e.title) }
      last_response.body.should include(calendar2.title)
    end

    it "doesn't include holidays in the result" do
      get "/calendars/#{calendar2.id}.html?#{api_key}"
      last_response.status.should == 200
      calendar2.events.each   { |e| last_response.body.should include(e.title) }
      calendar2.holidays.each { |e| last_response.body.should_not include(e.title) }
      last_response.body.should include(calendar2.title)
    end
  end

  describe "GET /calendars/:id.ical" do
    it "includes holidays in the result" do
      get "/calendars/#{calendar2.id}.ical?#{api_key}&holidays=true"
      should respond_with(200, :ical, calendar2.events + calendar2.holidays)
    end

    it "doesn't include holidays in the result" do
      get "/calendars/#{calendar2.id}.ical?#{api_key}"
      should respond_with(200, :ical, calendar2.events)
    end
  end

  describe "GET /calendars/:id/events.html" do
    it "includes holidays in the result" do
      get "/calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events.html?#{api_key}&holidays=true"
      last_response.status.should == 200
      calendar1.events.each   { |e| last_response.body.should include(e.title) }
      calendar1.holidays.each { |e| last_response.body.should include(e.title) }
      calendar2.events.each   { |e| last_response.body.should include(e.title) }
      calendar2.holidays.each { |e| last_response.body.should include(e.title) }
      last_response.body.should include(calendar1.title)
      last_response.body.should include(calendar2.title)
    end

    it "doesn't include holidays in the result" do
      get "/calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events.html?#{api_key}"
      last_response.status.should == 200
      calendar1.events.each   { |e| last_response.body.should     include(e.title) }
      calendar1.holidays.each { |e| last_response.body.should_not include(e.title) }
      calendar2.events.each   { |e| last_response.body.should     include(e.title) }
      calendar2.holidays.each { |e| last_response.body.should_not include(e.title) }
      last_response.body.should include(calendar1.title)
      last_response.body.should include(calendar2.title)
    end
  end

  describe "GET /calendars/:id/events.ical" do
    it "includes holidays in the result" do
      get "/calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events.ical?#{api_key}&holidays=true"
      should respond_with(200, :ical,
        calendar1.events + calendar2.events + calendar1.holidays + calendar2.holidays)
    end
    it "doesn't include holidays in the result" do
      get "/calendars/#{calendar1.id},#{calendar2.id},#{calendar3.id}/events.ical?#{api_key}"
      should respond_with(200, :ical, calendar1.events + calendar2.events)
    end
  end

  describe "GET /calendars/:id/events/:id.html"  do
    it "doesn't include holidays in the result" do
      get "/calendars/#{calendar2.id}/events/#{event3.id}.html?#{api_key}"
      last_response.status.should == 200
      last_response.body.should include(event3.title)
      last_response.body.should_not include(event4.title)
      calendar2.holidays.each { |e| last_response.body.should_not include(e.title) }
      last_response.body.should include(calendar2.title)
    end

    it "doesn't include holidays in the result" do
      get "/calendars/#{calendar2.id}/events/#{event3.id}.html?#{api_key}&holidays=true"
      last_response.status.should == 200
      last_response.body.should include(event3.title)
      last_response.body.should_not include(event4.title)
      calendar2.holidays.each { |e| last_response.body.should_not include(e.title) }
      last_response.body.should include(calendar2.title)
    end
  end
end

