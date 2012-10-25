require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe CalendarAPI do
    describe "Helpers" do
      describe "#extract" do
        it "extracts hash" do
          c = Class.new { include CalendarAPI::Helpers }.new
          c.extract({:a => 1, :b => 2, :c => 3}, :a, :c).should == {:a => 1, :c => 3}
        end

        it "skips unmached attributes" do
          c = Class.new { include CalendarAPI::Helpers }.new
          c.extract({:a => 1, :b => 2, :c => 3}, :a, :d).should == {:a => 1}
        end
      end
    end

    describe "GET /calendars" do
      let(:valid_params_1) { {"title" => "foo1", "description" => "bar1"} }
      let(:valid_params_2) { {"title" => "foo2" } }

      before do
        Calendar.create(valid_params_1.merge("owner_id" => "1234"))
        Calendar.create(valid_params_2.merge("owner_id" => "1234"))
        get "/calendars"
      end

      it { last_response.status.should == 200 }

      it "returns all the calendars" do
        json_parse(last_response).should == [valid_params_1, valid_params_2]
      end
    end

    describe "POST /calendars" do
      let(:valid_params) { {:title => "foo3", :description => "bar3"} }

      context "when parameters are valid" do
        before { post "/calendars", valid_params }

        it { last_response.status.should == 201 }

        it "creates a new calendar" do
          expect { post "/calendars", valid_params }.
            to change(Calendar, :count).by(+1)
        end

        it "doesn't include 'owner_id' in response" do
          json_parse(last_response).has_key?("owner_id").should be_false
        end

        it "doesn't allow the user to assign 'owner_id'" do
          post "/calendars", valid_params.merge(:owner_id => "value")
          Calendar.where(:owner_id => "value").all.should == []
        end

        it "doesn't allow the user to assign 'id'" do
          post "/calendars", valid_params.merge(:id => 123)
          Calendar.find(123).should == nil
        end
      end

      context "when parameters are invalid" do
        describe "validates the presense of 'title'" do
          let(:invalid_params) { valid_params.merge(:title => "") }

          before { post "calendars", invalid_params }

          it { last_response.status.should == 401 }

          it "doesn't create a new record" do
            expect { post "calendars", invalid_params }.
              to change(Calendar, :count).by(0)
          end

          it "returns an error message" do
            json_parse(last_response).should ==
              { "errors" => { "title" => ["can't be blank"] } }
          end
        end

        describe "validates the length of title" do
          let(:invalid_params) { valid_params.merge(:title => "a" * 41) }

          before { post "calendars", invalid_params }

          it { last_response.status.should == 401 }

          it "doesn't create a new record" do
            expect { post "calendars", invalid_params }.
              to change(Calendar, :count).by(0)
          end

          it "returns an error message" do
            json_parse(last_response).should == { "errors" => 
              { "title" => ["must be equal or less than 40 characters long"] } }
          end
        end

        describe "validates the length of description" do
          let(:invalid_params) { valid_params.merge(:description => "a" * 1001) }
          
          before { post "calendars", invalid_params }

          it { last_response.status.should == 401 }

          it "doesn't create a new record" do
            expect { post "calendars", invalid_params }.
              to change(Calendar, :count).by(0)
          end

          it "returns an error message" do
            json_parse(last_response).should == { "errors" => 
              { "description" => ["must be equal or less than 1000 characters long"] } }
          end
        end

      end
    end

    describe "GET /calendars/:id" do
      context "when parameters are valid" do
        let(:valid_params) { {:title => "qqq", :description => "q"} }
        let(:calendar) { Calendar.create(valid_params) }

        before { get "/calendars/#{calendar.id.to_s}" }

        it { last_response.status.should == 200 }

        it "doesn't include 'owner_id'" do
          json_parse(last_response).has_key?("owner_id").should be_false
        end

        it "returns corresponding object" do
          json_parse(last_response) == valid_params
        end
      end

      context "when parameters are invalid" do
        before { get "/calendars/1234124234" }

        it { last_response.status.should == 404 }
        it { json_parse(last_response).should == { "errors" => "Not Found" } }
      end
    end

    describe "PUT /calendars/:id" do
      let(:origin_params) { {"title" => "abc", "description" => "cba"} }
      let(:valid_params)  { {"title" => "111", "description" => "222"} }
      let(:calendar) { Calendar.create(origin_params) }

      context "when parameters are valid" do
        before { put "/calendars/#{calendar.id.to_s}", valid_params }

        it { last_response.status.should == 200 }

        it "doesn't include 'owner_id'" do
          json_parse(last_response).has_key?("owner_id").should be_false
        end

        it "updates the object" do
          json_parse(last_response).should == valid_params
          Calendar.find(calendar.id).title.should == valid_params["title"]
          Calendar.find(calendar.id).description.should == valid_params["description"]
        end
      end

      context "when parameters are invalid" do
        context "when 'id' is invalid" do
          let(:invalid_id) { 12331231231312312 }
          before { put "/calendars/#{invalid_id}", valid_params }

          it { last_response.status.should == 404 }
          it { json_parse(last_response).should == { "errors" => "Not Found" } }
        end

        context "when 'title' is blank" do
          let(:invalid_params) { valid_params.merge("title" => "") }
          before { put "/calendars/#{calendar.id.to_s}", invalid_params }

          it { last_response.status.should == 401 }

          it "doesn't update the object" do
            Calendar.find(calendar.id).title.should == origin_params["title"]
            Calendar.find(calendar.id).description.should == origin_params["description"]
          end

          it "returns an error message" do
            json_parse(last_response).should ==
              { "errors" => { "title" => ["can't be blank"] } }
          end
        end

        context "when 'title' is too long" do
          let(:invalid_params) { valid_params.merge("title" => "1"*41) }
          before { put "/calendars/#{calendar.id.to_s}", invalid_params }
          
          it { last_response.status.should == 401 }

          it "doesn't update the object" do
            Calendar.find(calendar.id).title.should == origin_params["title"]
            Calendar.find(calendar.id).description.should == origin_params["description"]
          end

          it "returns an error message" do
            json_parse(last_response).should == { "errors" => 
              { "title" => ["must be equal or less than 40 characters long"] } }
          end
        end
      end
    end

    describe "DELETE /calendars/:id" do
      let(:calendar) { Calendar.create("title" => "abc", "description" => "cba") }

      context "when parameters are valid" do
        before { delete "/calendars/#{calendar.id.to_s}" }

        it { last_response.status.should == 200 }
        it { Calendar.find(calendar.id).should == nil }
      end

      context "when parameters are invalid" do
        before { delete "/calendars/21312312312" }

        it { last_response.status.should == 404 }
        it { json_parse(last_response).should == { "errors" => "Not Found" } }
      end
    end
    
    describe "GET /events" do
      context "when parameters are valid" do
        before { get "/calendars/1/events" }

        it { last_response.status.should == 200 }

        it "returns events for the calendar" do
        end
      end

      context "when parameters are invalid" do
      end
    end
  end
end

