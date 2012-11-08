require "spec_helper.rb"

describe Event do
  describe ".search" do
    let!(:customer) { create(:customer) }
    let!(:customer2) { create(:customer) }

    let!(:calendar1) { create(:calendar, customer: customer) }
    let!(:calendar2) { create(:calendar, customer: customer) }
    let!(:calendar3) { create(:calendar, customer: customer) }
    let!(:calendar4) { create(:calendar, customer: customer2) }

    let!(:event_1) { create(:event, calendar: calendar1, start: 9.days.ago.to_i, end: 1.day.ago.to_i) }
    let!(:event_2) { create(:event, calendar: calendar1, start: 5.days.ago.to_i, end: 4.day.ago.to_i )}
    let!(:event_3) { create(:event, calendar: calendar2, start: 8.days.ago.to_i, end: 7.day.ago.to_i )}
    let!(:event_4) { create(:event, calendar: calendar3, start: 5.days.ago.to_i, end: 1.day.ago.to_i)}
    let!(:event_5) { create(:event, calendar: calendar4, start: 5.days.ago.to_i, end: 1.day.ago.to_i)}
    let!(:event_6) { create(:event, calendar: calendar4, start: 9.days.ago.to_i, end: 1.day.ago.to_i)}

    context "when many users are involved" do
      it "uses calendar's customer association to assign customer_id" do
        event = calendar4.events.build(attributes_for(:event))
        event.save
        event.customer.should == calendar4.customer
        event.customer.should == customer2
      end

      it "ignores the data which doesn't belong to the current user" do
        params = mash(calendar_ids: calendar2.id.to_s)
        Event.search(params, customer2).to_a.should == []

        params = mash(calendar_ids: "#{calendar1.id},#{calendar2.id},#{calendar3.id}")
        Event.search(params, customer2).to_a.should == []

        params = mash(calendar_ids: "#{calendar1.id},#{calendar2.id},#{calendar3.id},#{calendar4.id}")
        Event.search(params, customer2).to_a.should == [ event_5, event_6 ]

        params = mash(calendar_ids: calendar4.id.to_s)
        Event.search(params, customer).to_a.should == []

        params = mash(calendar_ids: calendar4.id.to_s)
        Event.search(params, customer2).to_a.should == [ event_5, event_6 ]
      end
    end

    context "without the time filter" do
      it "returns matched events for multiple calendars" do
        params = mash(calendar_ids: "#{calendar1.id},#{calendar3.id}")
        Event.search(params, customer).to_a.should == [ event_1, event_2, event_4 ]
      end

      it "returns matched events for a signle calendar" do
        params = mash(calendar_ids: calendar2.id.to_s)
        Event.search(params, customer).to_a.should == [ event_3 ]
      end

      it "returns an empty array if nothing has been found" do
        params = mash(calendar_ids: "123123123131")
        Event.search(params, customer).to_a.should == []
      end
    end

    context "with the time filter" do
      it "returns matched events" do
        params = mash(calendar_ids: "#{calendar1.id},#{calendar2.id}",
          :start => 6.days.ago.to_i, :end => 4.days.ago.to_i)
        Event.search(params, customer).to_a.should == [event_2]

        params = mash(:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          :start => 5.days.ago.to_i, :end => 1.days.ago.to_i)
        Event.search(params, customer).to_a.should == [event_2, event_4]

        params = mash(:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          :start => 9.days.ago.to_i, :end => 1.days.ago.to_i)
        Event.search(params, customer).to_a.should == [event_1, event_2, event_3, event_4]

        params = mash(:calendar_ids => "#{calendar2.id},#{calendar3.id}",
          :start => 8.days.ago.to_i, :end => 6.days.ago.to_i)
        Event.search(params, customer).to_a.should == [event_3]
      end
    end
  end
end

