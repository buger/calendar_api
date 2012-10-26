require "spec_helper.rb"

describe Event do
  describe ".search" do
    let(:calendar1) { Calendar.create("title" => "abc") }
    let(:calendar2) { Calendar.create("title" => "qqq") }
    let(:calendar3) { Calendar.create("title" => "___") }

    let!(:event_1) { calendar1.events.create(:title => "1", :start => 9.days.ago, :end => 1.day.ago ) }
    let!(:event_2) { calendar1.events.create(:title => "2", :start => 5.days.ago, :end => 4.day.ago ) }
    let!(:event_3) { calendar2.events.create(:title => "3", :start => 8.days.ago, :end => 7.day.ago ) }
    let!(:event_4) { calendar3.events.create(:title => "4", :start => 5.days.ago, :end => 1.day.ago ) }

    context "without the time filter" do
      it "returns matched events for multiple calendars" do
        params = { :calendar_ids => "#{calendar1.id},#{calendar3.id}" }
        Event.search(params).to_a.should == [ event_1, event_2, event_4 ]
      end

      it "returns matched events for a signle calendar" do
        params = { :calendar_ids => calendar2.id.to_s }
        Event.search(params).to_a.should == [ event_3 ]
      end

      it "returns an empty array if nothing has been found" do
        params = { :calendar_ids => "123123123131"}
        Event.search(params).to_a.should == []
      end
    end

    context "with the time filter" do
      it "returns matched events" do
        params = { :calendar_ids => "#{calendar1.id},#{calendar2.id}",
          "start" => 6.days.ago.to_s, "end" => 4.days.ago.to_s }
        Event.search(params).to_a.should == [event_2]

        params = { :calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          "start" => 5.days.ago.to_s, "end" => 1.days.ago.to_s }
        Event.search(params).to_a.should == [event_2, event_4]

        params = { :calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          "start" => 9.days.ago.to_s, "end" => 1.days.ago.to_s }
        Event.search(params).to_a.should == [event_1, event_2, event_3, event_4]

        params = { :calendar_ids => "#{calendar2.id},#{calendar3.id}",
          "start" => 8.days.ago.to_s, "end" => 6.days.ago.to_s }
        Event.search(params).to_a.should == [event_3]
      end
    end
  end
end

