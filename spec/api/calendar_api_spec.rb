require "spec_helper.rb"
require "icalendar"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe CalendarAPI do
    let(:customer) { create(:customer) }
    let(:api_key) { { api_key: customer.api_key }.to_query }

    describe "GET /calendars" do
      let!(:calendar1) { create(:calendar, customer: customer) }
      let!(:calendar2) { create(:calendar, customer: customer) }

      it "returns all the calendars" do
        get "/calendars?#{api_key}"
        should respond_with_calendars(200, :json, calendar1, calendar2)
     end
    end

    describe "POST /calendars" do
      let(:params) { attributes_for(:calendar, id: 123, customer_id: 124) }

      context "when parameters are valid" do
        it "creates a new calendar" do
          post "/calendars?#{api_key}", params
          should respond_with(201, :json, params.slice(:country, :title))
          Calendar.count.should == 1
          Calendar.last.customer_id.should_not == params[:customer_id]
          Calendar.last.id.should_not == params[:id]
          Calendar.last.customer_id.should == customer.id
        end
      end

      context "when parameters are invalid" do
        it "returns an error if 'title' is not provided" do
          post "calendars?#{api_key}", params.merge(title: "")
          should respond_with(401, :json, errors: { "title" => ["can't be blank"] })
          Calendar.count.should == 0
        end

        it "returns an error if 'title' is too long" do
          post "calendars?#{api_key}", params.merge(title: "a" * 41)
          should respond_with(401, :json, errors:
            { "title" => ["must be equal or less than 40 characters long"] })
          Calendar.count.should == 0
        end

        it "returns an error if 'describe' is too long" do
          post "calendars?#{api_key}", params.merge(description: "a" * 1000)
          should respond_with(401, :json, errors:
            { "description" => ["must be equal or less than 1000 characters long"] })
          Calendar.count.should == 0
        end
      end
    end

    describe "GET /calendars/:id" do
      let(:params) { attributes_for(:calendar, description: "q") }
      let(:calendar) { create(:calendar, params.merge(customer: customer)) }
      let(:calendar2) { create(:calendar, params.merge(customer: customer)) }

      it "returns the calendar" do
        get "/calendars/#{calendar.id}?#{api_key}"
        should respond_with(200, :json, params.slice(:country, :description, :title))
      end

      it "returns an error if 'id' is invalid" do
        get "/calendars/1234124234?#{api_key}"
        should respond_with(404, :json, errors: "Not Found")
      end

      context ".ical" do
        let!(:event_1) { create(:event, calendar: calendar,  dtstart: 9.days.ago, dtend: 5.days.ago) }
        let!(:event_2) { create(:event, calendar: calendar,  dtstart: 6.days.ago, dtend: 3.days.ago) }
        let!(:event_3) { create(:event, calendar: calendar2, dtstart: 7.days.ago, dtend: 1.days.ago) }

        it "returns the calendar in .ical format" do
          get "/calendars/#{calendar.id}.ical?#{api_key}"
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
          put "/calendars/#{calendar.id}?#{api_key}", new_params
          last_response.status.should == 200
          last_response.body.should == new_params.slice(:country, :description, :title).to_json

          calendar.reload
          calendar.title.should == new_params[:title]
          calendar.description.should == new_params[:description]
        end
      end

      context "when parameters are invalid" do
        it "returns an error if 'id' if invalid" do
          put "/calendars/123213123?#{api_key}", new_params
          should respond_with(404, :json, errors: "Not Found")
        end

        it "returns an error if 'title' is blank" do
          put "/calendars/#{calendar.id}?#{api_key}", new_params.merge(:title => "")
          should respond_with(401, :json, errors: { "title" => ["can't be blank"] })
          calendar.reload
          calendar.title.should == origin_params[:title]
          calendar.description.should == origin_params[:description]
        end

        it "returns an error if 'title' is too long" do
          put "/calendars/#{calendar.id}?#{api_key}", new_params.merge("title" => "1"*41)
          should respond_with(401, :json, errors:
             { "title" => ["must be equal or less than 40 characters long"] })
          calendar.reload
          calendar.title.should == origin_params[:title]
          calendar.description.should == origin_params[:description]
        end

        it "returns an error if 'description' is too long" do
          put "/calendars/#{calendar.id}?#{api_key}", new_params.merge("description" => "1"*1000)
          should respond_with(401, :json, errors:
             { "description" => ["must be equal or less than 1000 characters long"] })
          calendar.reload
          calendar.title.should == origin_params[:title]
          calendar.description.should == origin_params[:description]
        end
      end
    end

    describe "DELETE /calendars/:id" do
      let!(:calendar) { create(:calendar, :customer => customer) }

      it "removes the calendar" do
        delete "/calendars/#{calendar.id}?#{api_key}"
        last_response.status.should == 200
        Calendar.find(calendar.id).should == nil
      end

      it "returns an error if 'id' is invalid" do
        delete "/calendars/21312312312?#{api_key}"
        should respond_with(404, :json, errors: "Not Found")
      end
    end
  end
end

