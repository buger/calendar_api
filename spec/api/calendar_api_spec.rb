require "spec_helper.rb"
require "icalendar"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe CalendarAPI do
    let(:customer) { create(:customer) }
    let(:api_key) { { :api_key => customer.api_key }.to_query }

    describe "GET /calendars" do
      let(:params1) { attributes_for(:calendar) }
      let!(:calendar1) { create(:calendar, params1.merge(:customer => customer)) }

      it "returns all the calendars" do
        get "/calendars?#{api_key}"
        last_response.status.should == 200
        last_response.body.should == [params1.slice(:country, :title)].to_json
      end
    end

    describe "POST /calendars" do
      let(:params) { attributes_for(:calendar, :id => 123, :customer_id => 124) }

      context "when parameters are valid" do
        it "creates a new calendar" do
          post "/calendars?#{api_key}", params
          last_response.status.should == 201
          last_response.body.should == params.slice(:country, :title).to_json
          Calendar.count.should == 1
          Calendar.last.customer_id.should_not == params[:customer_id]
          Calendar.last.id.should_not == params[:id]
          Calendar.last.customer_id.should == customer.id
        end
      end

      context "when parameters are invalid" do
        it "returns an error if 'title' is not provided" do
          post "calendars?#{api_key}", params.merge(:title => "")
          last_response.status.should == 401
          last_response.body.should == { :errors => { "title" => ["can't be blank"] } }.to_json
          Calendar.count.should == 0
        end

        it "returns an error if 'title' is too long" do
          post "calendars?#{api_key}", params.merge(:title => "a" * 41)
          last_response.status.should == 401
          last_response.body.should == { :errors => 
            { "title" => ["must be equal or less than 40 characters long"] } }.to_json
          Calendar.count.should == 0
        end

        it "returns an error if 'describe' is too long" do
          post "calendars?#{api_key}", params.merge(:description => "a" * 1000)
          last_response.status.should == 401
          last_response.body.should == { :errors => 
            { "description" => ["must be equal or less than 1000 characters long"] } }.to_json
          Calendar.count.should == 0
        end
      end
    end

    describe "GET /calendars/:id" do
      let(:params) { attributes_for(:calendar, :description => "q") }
      let(:calendar) { create(:calendar, params.merge(:customer => customer)) }

      it "returns the calendar" do
        get "/calendars/#{calendar.id}?#{api_key}"
        last_response.status.should == 200
        last_response.body.should == Hash[params.slice(:country, :description, :title).sort].to_json
      end

      it "returns an error if 'id' is invalid" do
        get "/calendars/1234124234?#{api_key}"
        should response_with_error(404, "Not Found")
      end

      describe "GET /calendars/:id.ical" do
        let!(:event_1) { create(:event, :calendar => calendar, :start => 9.days.ago, :end => 5.days.ago) }
        let!(:event_2) { create(:event, :calendar => calendar, :start => 6.days.ago, :end => 3.days.ago) }

        it "returns the calendar in .ical format" do
          get "/calendars/#{calendar.id}.ical?#{api_key}"
          last_response.status.should == 200
          last_response.header["Content-Type"].should == "text/calendar"
          Icalendar.parse(last_response.body).first.events.size.should == calendar.events.size
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
          should response_with_error(404, "Not Found")
        end

        it "returns an error if 'title' is blank" do
          put "/calendars/#{calendar.id}?#{api_key}", new_params.merge(:title => "")
          last_response.status.should == 401
          last_response.body.should == { :errors => { "title" => ["can't be blank"] } }.to_json

          calendar.reload
          calendar.title.should == origin_params[:title]
          calendar.description.should == origin_params[:description]
        end

        it "returns an error if 'title' is too long" do
          put "/calendars/#{calendar.id}?#{api_key}", new_params.merge("title" => "1"*41)
          last_response.status.should == 401
          last_response.body.should == { :errors => 
             { "title" => ["must be equal or less than 40 characters long"] } }.to_json
          calendar.reload
          calendar.title.should == origin_params[:title]
          calendar.description.should == origin_params[:description]
        end

        it "returns an error if 'description' is too long" do
          put "/calendars/#{calendar.id}?#{api_key}", new_params.merge("description" => "1"*1000)
          last_response.status.should == 401
          last_response.body.should == { :errors => 
             { "description" => ["must be equal or less than 1000 characters long"] } }.to_json
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
        should response_with_error(404, "Not Found")
      end
    end
  end
end

