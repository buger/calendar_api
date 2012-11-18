require "spec_helper.rb"
require "rspec-html-matchers"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe "HTML Rendering" do
    let!(:customer) { create(:customer) }
    let!(:api_key) { { api_key: customer.api_key }.to_query }

    let!(:calendar) { create(:calendar, customer: customer) }

    describe "GET /calendars/:id.html" do
      it "renders html" do
        get "/calendars/#{calendar.id}.html?#{api_key}&holidays=true"
        last_response.status.should == 200
        last_response.body.should have_tag("h1", text: "Calendar: #{calendar.title}")
      end
    end
  end
end
