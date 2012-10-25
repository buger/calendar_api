require "spec_helper.rb"

describe CalendarAPI do
  include Rack::Test::Methods

  def app
    CalendarAPI
  end

  describe CalendarAPI do
    before :each do
      Calendar.create(:title => "foo", 
        :description => "bar", :owner_id => "1234")
      Calendar.create(:title => "foo1", 
        :description => "bar1", :owner_id => "1234")
    end

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
      before { get "/calendars" }

      it { last_response.status.should == 200 }

      it "doesn't include 'owner_id'" do
        json_parse(last_response).each do |object|
          object.has_key?("owner_id").should be_false
        end
      end

      it "returns all the calendars" do
        json_parse(last_response).should ==
          [{"title" => "foo", "description" => "bar"},
           {"title" => "foo1", "description" => "bar1"}]
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

        it "ignores 'owner_id' attribute in the user's request" do
          Calendar.where(:owner_id => "value").all.should == []
        end
      end

      context "when parameters are invalid" do
        describe "validates presense of 'title'" do
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

        describe "validates presense of 'description'" do
          let(:invalid_params) { valid_params.merge(:description => "") }

          before { post "calendars", invalid_params }

          it "returns 401 status code" do
            last_response.status.should == 401
          end

          it "doesn't create a new record" do
            expect { post "calendars", invalid_params }.
              to change(Calendar, :count).by(0)
          end

          it "returns an error message" do
            json_parse(last_response).should ==
              { "errors" => { "description" => ["can't be blank"] } }
          end
        end

        describe "validates length of title" do
          before { valid_params.merge!(:title => "a" * 41) }
          
          before { post "calendars", valid_params }

          it { last_response.status.should == 401 }

          it "doesn't create a new record" do
            expect { post "calendars", valid_params }.
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

        before { get "/calendars/#{calendar.id.to_s}", valid_params }

        it { last_response.status.should == 200 }

        it "doesn't include 'owner_id'" do
          json_parse(last_response).has_key?("owner_id").should be_false
        end

        it "returns corresponding object" do
          json_parse(last_response) == valid_params
        end
      end

      context "when parameters are invalid" do
        before { get "/calendars/1234124234", @params }

        it { last_response.status.should == 404 }
        it { json_parse(last_response).should == { "errors" => "Not Found" } }
      end
    end

    describe "PUT /calendars/:id" do
      let(:params) { {"title" => "abc", "description" => "cba"} }
      let(:calendar) { Calendar.create(:title => "111", :description => "000") }

      context "when parameters are valid" do
        before { put "/calendars/#{calendar.id.to_s}", params }

        it { last_response.status.should == 200 }

        it "doesn't include 'owner_id'" do
          json_parse(last_response).has_key?("owner_id").should be_false
        end

        it "updates the object" do
          json_parse(last_response).should == params
          Calendar.where("title" => "abc").all.last["description"].should == "cba"
        end
      end

      context "when parameters are invalid" do
        context "when 'id' is invalid" do
          let(:invalid_id) { 12331231231312312 }
          before { put "/calendars/#{invalid_id}", params }

          it { last_response.status.should == 404 }
          it { json_parse(last_response).should == { "errors" => "Not Found" } }
        end

        context "when 'title' is blank" do
          let(:invalid_params) { params.merge("title" => "") }
          before { put "/calendars/#{calendar.id.to_s}", invalid_params }

          it { last_response.status.should == 401 }

          it "doesn't update the object" do
            Calendar.find(calendar.id.to_s).title.should == "111"
          end

          it "returns an error message" do
            json_parse(last_response).should ==
              { "errors" => { "title" => ["can't be blank"] } }
          end
        end

        context "when 'description' is blank" do
          let(:invalid_params) { params.merge("description" => "") }
          before { put "/calendars/#{calendar.id.to_s}", invalid_params }

          it { last_response.status.should == 401 }

          it "doesn't update the object" do
            Calendar.find(calendar.id.to_s).description.should == "000"
          end

          it "returns an error message" do
            json_parse(last_response).should ==
              { "errors" => { "description" => ["can't be blank"] } }
          end
        end
      end
    end

    describe "DELETE /calendars/:id" do
      let(:calendar) { Calendar.create("title" => "abc", "description" => "cba") }

      context "when parameters are valid" do
        before { delete "/calendars/#{calendar.id.to_s}" }

        it { last_response.status.should == 200 }
        it { Calendar.find(calendar.id.to_s).should == nil }
      end

      context "when parameters are invalid" do
        before { delete "/calendars/21312312312" }

        it { last_response.status.should == 404 }
        it { json_parse(last_response).should == { "errors" => "Not Found" } }
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

