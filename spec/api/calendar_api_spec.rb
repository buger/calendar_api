require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe CalendarAPI do
    describe "GET /calendars" do
      let(:params1) { attributes_for(:calendar) }
      let!(:calendar1) { create(:calendar, params1) }

      it "returns all the calendars" do
        get "/calendars"
        last_response.status.should == 200
        last_response.body.should == [params1.slice(:title)].to_json
      end
    end

    describe "POST /calendars" do
      let(:params) { attributes_for(:calendar, :id => 123, :owner_id => 124) }

      context "when parameters are valid" do
        it "creates a new calendar" do
          post "/calendars", params
          last_response.status.should == 201
          last_response.body.should == params.slice(:title).to_json
          Calendar.count.should == 1
          Calendar.last.owner_id.should_not == params[:owner_id]
          Calendar.last.id.should_not == params[:id]
        end
      end

      context "when parameters are invalid" do
        it "returns an error if 'title' is not provided" do
          post "calendars", params.merge(:title => "")
          last_response.status.should == 401
          last_response.body.should == { :errors => { "title" => ["can't be blank"] } }.to_json
          Calendar.count.should == 0
        end

        it "returns an error if 'title' is too long" do
          post "calendars", params.merge(:title => "a" * 41)
          last_response.status.should == 401
          last_response.body.should == { :errors => 
            { "title" => ["must be equal or less than 40 characters long"] } }.to_json
          Calendar.count.should == 0
        end

        it "returns an error if 'describe' is too long" do
          post "calendars", params.merge(:description => "a" * 1000)
          last_response.status.should == 401
          last_response.body.should == { :errors => 
            { "description" => ["must be equal or less than 1000 characters long"] } }.to_json
          Calendar.count.should == 0
        end
      end
    end

    describe "GET /calendars/:id" do
      let(:params) { attributes_for(:calendar, :description => "q") }
      let(:calendar) { create(:calendar, params) }

      it "returns the calendar" do
        get "/calendars/#{calendar.id}"
        last_response.status.should == 200
        last_response.body.should == Hash[params.slice(:title, :description).sort].to_json
      end

      it "returns an error if 'id' is invalid" do
        get "/calendars/1234124234"
        last_response.status.should == 404
        last_response.body.should == { :errors => "Not Found" }.to_json
      end
    end

    describe "PUT /calendars/:id" do
      let(:origin_params) { attributes_for(:calendar) }
      let(:new_params) { attributes_for(:calendar, :description => "q") }
      let(:calendar) { create(:calendar, origin_params) }

      context "when parameters are valid" do
        it "updates the object" do
          put "/calendars/#{calendar.id}", new_params
          last_response.status.should == 200
          last_response.body.should == new_params.slice(:description, :title).to_json

          calendar.reload
          calendar.title.should == new_params[:title]
          calendar.description.should == new_params[:description]
        end
      end

      context "when parameters are invalid" do
        it "returns an error if 'id' if invalid" do
          put "/calendars/123213123", new_params
          last_response.status.should == 404
          last_response.body.should == { :errors => "Not Found" }.to_json
        end

        it "returns an error if 'title' is blank" do
          put "/calendars/#{calendar.id}", new_params.merge(:title => "")
          last_response.status.should == 401
          last_response.body.should == { :errors => { "title" => ["can't be blank"] } }.to_json

          calendar.reload
          calendar.title.should == origin_params[:title]
          calendar.description.should == origin_params[:description]
        end

        it "returns an error if 'title' is too long" do
          put "/calendars/#{calendar.id}", new_params.merge("title" => "1"*41)
          last_response.status.should == 401
          last_response.body.should == { :errors => 
             { "title" => ["must be equal or less than 40 characters long"] } }.to_json
          calendar.reload
          calendar.title.should == origin_params[:title]
          calendar.description.should == origin_params[:description]
        end

        it "returns an error if 'description' is too long" do
          put "/calendars/#{calendar.id}", new_params.merge("description" => "1"*1000)
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
      let!(:calendar) { create(:calendar) }

      it "removes the calendar" do
        delete "/calendars/#{calendar.id}"
        last_response.status.should == 200
        Calendar.find(calendar.id).should == nil
      end

      it "returns an error if 'id' is invalid" do
        delete "/calendars/21312312312"
        last_response.status.should == 404
        last_response.body.should == { :errors => "Not Found" }.to_json
      end
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

    describe "POST /calendars/:id/events" do
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
  end
end

