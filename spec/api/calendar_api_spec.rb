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
  end
end

