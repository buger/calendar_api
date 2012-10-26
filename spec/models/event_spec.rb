require "spec_helper.rb"

describe Event do
  describe ".search" do
    let(:calendar1) { create(:calendar) }
    let(:calendar2) { create(:calendar) }
    let(:calendar3) { create(:calendar) }

    let!(:event_1) { create(:event, :calendar => calendar1, :start => 9.days.ago.to_i, :end => 1.day.ago.to_i)}
    let!(:event_2) { create(:event, :calendar => calendar1, :start => 5.days.ago.to_i, :end => 4.day.ago.to_i)}
    let!(:event_3) { create(:event, :calendar => calendar2, :start => 8.days.ago.to_i, :end => 7.day.ago.to_i)}
    let!(:event_4) { create(:event, :calendar => calendar3, :start => 5.days.ago.to_i, :end => 1.day.ago.to_i)}

    context "without the time filter" do
      it "returns matched events for multiple calendars" do
        params = Hashie::Mash[:calendar_ids => "#{calendar1.id},#{calendar3.id}"]
        Event.search(params).to_a.should == [ event_1, event_2, event_4 ]
      end

      it "returns matched events for a signle calendar" do
        params = Hashie::Mash[:calendar_ids => calendar2.id.to_s]
        Event.search(params).to_a.should == [ event_3 ]
      end

      it "returns an empty array if nothing has been found" do
        params = Hashie::Mash[:calendar_ids => "123123123131"]
        Event.search(params).to_a.should == []
      end
    end

    context "with the time filter" do
      it "returns matched events" do
        params = Hashie::Mash[:calendar_ids => "#{calendar1.id},#{calendar2.id}",
          :start => 6.days.ago.to_i, :end => 4.days.ago.to_i]
        Event.search(params).should == [event_2]

        params = Hashie::Mash[:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          :start => 5.days.ago.to_i, :end => 1.days.ago.to_i]
        Event.search(params).should == [event_2, event_4]

        params = Hashie::Mash[:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          :start => 9.days.ago.to_i, :end => 1.days.ago.to_i]
        Event.search(params).should == [event_1, event_2, event_3, event_4]

        params = Hashie::Mash[:calendar_ids => "#{calendar2.id},#{calendar3.id}",
          :start => 8.days.ago.to_i, :end => 6.days.ago.to_i]
        Event.search(params).should == [event_3]
      end
    end
  end
end

