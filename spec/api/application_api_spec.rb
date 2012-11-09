require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe CalendarAPI do
    context "api keys" do
      let!(:customer1) { create(:customer) }
      let!(:customer2) { create(:customer) }
      let!(:api_key1) { { api_key: customer1.api_key }.to_query }
      let!(:api_key2) { { api_key: customer2.api_key }.to_query }
      let!(:attrs1) { attributes_for(:calendar) }
      let!(:attrs2) { attributes_for(:calendar) }
      let!(:attrs3) { attributes_for(:calendar) }
      let!(:calendar1) { create(:calendar, attrs1.merge(customer: customer1)) }
      let!(:calendar2) { create(:calendar, attrs2.merge(customer: customer2)) }
      let!(:calendar3) { create(:calendar, attrs3.merge(customer: customer2)) }

      it "requires api key" do
        get "/calendars"
        should respond_with(401, :json, error: "401 Unauthorized")

        api_key = { api_key: "1231231231232" }.to_query
        get "/calendars?#{api_key}"
        should respond_with(401, :json, error: "401 Unauthorized")
      end

      context "calendar" do
        it "doesn't allow the user to read other user's calendars in index" do
          api_key = { api_key: customer1.api_key }.to_query
          get "/calendars?#{api_key}"
          should respond_with_calendars(200, :json, attrs1)

          api_key = { api_key: customer2.api_key }.to_query
          get "/calendars?#{api_key}"
          should respond_with_calendars(200, :json, calendar2, calendar3)
        end
        
        it "doesn't allow the user to read other user's calendar" do
          api_key = { api_key: customer1.api_key }.to_query
          get "/calendars/#{calendar2.id}?#{api_key}"
          should respond_with(404, :json, errors: "Not Found")

          api_key = { api_key: customer2.api_key }.to_query
          get "/calendars/#{calendar2.id}?#{api_key}"
          should respond_with(200, :json, attrs2)

          api_key = { api_key: customer2.api_key }.to_query
          get "/calendars/#{calendar1.id}?#{api_key}"
          should respond_with(404, :json, errors: "Not Found")

          api_key = { api_key: customer1.api_key }.to_query
          get "/calendars/#{calendar1.id}?#{api_key}"
          should respond_with(200, :json, attrs1)
        end

        it "doesn't allow the user to edit other user's calendar" do
          api_key = { api_key: customer1.api_key }.to_query
          put "/calendars/#{calendar2.id}?#{api_key}", attributes_for(:calendar).slice(:title)
          should respond_with(404, :json, errors: "Not Found")
          calendar2.reload
          calendar2.title.should == attrs2[:title]

          new_attrs = attributes_for(:calendar)
          api_key = { api_key: customer2.api_key }.to_query
          put "/calendars/#{calendar2.id}?#{api_key}", new_attrs.slice(:country, :title)
          should respond_with(200, :json, new_attrs)
          calendar2.reload
          calendar2.title.should == new_attrs[:title]

          api_key = { api_key: customer2.api_key }.to_query
          put "/calendars/#{calendar1.id}?#{api_key}", attributes_for(:calendar).slice(:title)
          should respond_with(404, :json, errors: "Not Found")
          calendar1.reload
          calendar1.title.should == attrs1[:title]

          new_attrs = attributes_for(:calendar)
          api_key = { api_key: customer1.api_key }.to_query
          put "/calendars/#{calendar1.id}?#{api_key}", new_attrs.slice(:country, :title)
          should respond_with(200, :json, new_attrs)
          calendar1.reload
          calendar1.title.should == new_attrs[:title]
        end

        it "doesn't allow the user to destroy other user's calendar" do
          api_key = { :api_key => customer1.api_key }.to_query
          delete "/calendars/#{calendar2.id}?#{api_key}"
          should respond_with(404, :json, errors: "Not Found")

          api_key = { :api_key => customer2.api_key }.to_query
          delete "/calendars/#{calendar2.id}?#{api_key}"
          last_response.status.should == 200
          Calendar.find(calendar2.to_s).should == nil

          api_key = { :api_key => customer2.api_key }.to_query
          delete "/calendars/#{calendar1.id}?#{api_key}"
          should respond_with(404, :json, errors: "Not Found")

          api_key = { :api_key => customer1.api_key }.to_query
          delete "/calendars/#{calendar1.id}?#{api_key}"
          last_response.status.should == 200
          Calendar.find(calendar1.to_s).should == nil
        end
      end

      context "events" do
        let(:event_attrs1) { attributes_for(:event, start: 9.days.ago.to_i, end: 5.days.ago.to_i) }
        let(:event_attrs2) { attributes_for(:event, start: 6.days.ago.to_i, end: 4.days.ago.to_i) }
        let(:event_attrs3) { attributes_for(:event, start: 5.days.ago.to_i, end: 1.days.ago.to_i) }
        let(:event_attrs4) { attributes_for(:event, start: 7.days.ago.to_i, end: 3.days.ago.to_i) }

        let!(:event1) { create(:event, event_attrs1.merge(:calendar => calendar1)) }
        let!(:event2) { create(:event, event_attrs2.merge(:calendar => calendar1)) }
        let!(:event3) { create(:event, event_attrs3.merge(:calendar => calendar2)) }
        let!(:event4) { create(:event, event_attrs4.merge(:calendar => calendar3)) }

        it "doesn't allow the user to search for events in other user's calendar(s)" do
          get "/calendars/#{calendar2.id}/events?#{api_key1}"
          should respond_with(404, :json, errors: "Not Found")

          get "/calendars/#{calendar1.id}/events?#{api_key2}"
          should respond_with(404, :json, errors: "Not Found")

          get "/calendars/#{calendar2.id},#{calendar1.id}/events?#{api_key1}"
          should respond_with_events(200, :json, event1, event2)

          get "/calendars/#{calendar2.id},#{calendar1.id}/events?#{api_key2}"
          should respond_with_events(200, :json, event3)
        end

        it "doesn't allow the user to create events in other user's calendars" do
          post "/calendars/#{calendar1.id}/events?#{api_key2}", attributes_for(:event)
          should respond_with(404, :json, errors: "Not Found")

          post "/calendars/#{calendar2.id}/events?#{api_key1}", attributes_for(:event)
          should respond_with(404, :json, errors: "Not Found")

          attrs = attributes_for(:event)
          post "/calendars/#{calendar2.id}/events?#{api_key2}", attrs
          should respond_with(201, :json, Event.all.last)

          attrs = attributes_for(:event)
          post "/calendars/#{calendar1.id}/events?#{api_key1}", attrs
          should respond_with(201, :json, Event.all.last)
        end

        it "doesn't allow the user to read event in other user's calendar" do
          get "/calendars/#{calendar1.id}/events/#{event1.id}?#{api_key2}"
          should respond_with(404, :json, errors: "Not Found")

          get "/calendars/#{calendar1.id}/events/#{event2.id}?#{api_key2}"
          should respond_with(404, :json, errors: "Not Found")

          get "/calendars/#{calendar1.id}/events/#{event2.id}?#{api_key1}"
          last_response.status.should == 200
          should respond_with(200, :json, event2)

          get "/calendars/#{calendar2.id}/events/#{event3.id}?#{api_key1}"
          should respond_with(404, :json, errors: "Not Found")

          get "/calendars/#{calendar2.id}/events/#{event3.id}?#{api_key2}"
          last_response.status.should == 200
          should respond_with(200, :json, event3)
        end

        it "doesn't allow the user to edit event in other user's calendar" do
          new_attrs = attributes_for(:event)
          put "/calendars/#{calendar1.id}/events/#{event1.id}?#{api_key2}", new_attrs
          should respond_with(404, :json, errors: "Not Found")

          new_attrs = attributes_for(:event)
          put "/calendars/#{calendar1.id}/events/#{event1.id}?#{api_key1}", new_attrs
          should respond_with(200, :json, Event.find(event1.id))
        end

        it "doesn't allow the user to destroy event in other user's calendar" do
          delete "/calendars/#{calendar1.id}/events/#{event1.id}?#{api_key2}"
          should respond_with(404, :json, errors: "Not Found")

          delete "/calendars/#{calendar2.id}/events/#{event2.id}?#{api_key1}"
          should respond_with(404, :json, errors: "Not Found")

          expect do
            delete "/calendars/#{calendar1.id}/events/#{event1.id}?#{api_key1}"
            last_response.status.should == 200
          end.to change(Event, :count).by(-1)

          expect do
            delete "/calendars/#{calendar2.id}/events/#{event3.id}?#{api_key2}"
            last_response.status.should == 200
          end.to change(Event, :count).by(-1)
        end
      end
    end
  end
end

