require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe CalendarAPI do
    describe "GET /calendars" do
      it do
        get "/calendars"
        last_response.status.should == 200
      end
    end

    describe "GET /events" do
      it do
        get "/calendars/1/events"
        last_response.status.should == 200
      end
    end
  end
end

