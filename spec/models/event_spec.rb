require "spec_helper.rb"

describe Event do
  it { should belong_to(:calendar) }
  it { should belong_to(:holiday_calendar) }

  it { should allow_mass_assignment_of(:title) }
  it { should allow_mass_assignment_of(:description) }
  it { should allow_mass_assignment_of(:start) }
  it { should allow_mass_assignment_of(:end) }
  it { should allow_mass_assignment_of(:color) }

  it { should_not allow_mass_assignment_of(:holiday_calendar_id) }
  it { should_not allow_mass_assignment_of(:calendar_id) }

  it { should validate_presence_of(:title).on(:create, :update) }
  it { should validate_length_of(:title).within(1..40) }
  it { should validate_length_of(:description).within(0..1000) }
  it { should validate_length_of(:color).within(0..40) }

  it { should have_fields(:start, :end).of_type(Time) }

  describe "time formats" do
    let(:timestamp_start) { 9.days.ago.to_i }
    let(:timestamp_end)   { 5.days.ago.to_i }

    let(:customer) { create(:customer) }
    let(:calendar) { create(:calendar, customer: customer) }
    let(:event) { create(:event, calendar: calendar, start: timestamp_start, end: timestamp_end) }

    it ".end and .start should be in unix timestamp format, with miliseconds (for js)" do
      Time.at(event.start / 1000).to_i.should == timestamp_start
      Time.at(event.end / 1000).to_i.should == timestamp_end
    end
  end

  describe ".search" do
    def ago(n) n.days.ago.to_i end

    let!(:customer1) { create(:customer) }
    let!(:customer2) { create(:customer) }

    let!(:holiday_calendar1) { create(:holiday_calendar) }
    let!(:holiday_calendar2) { create(:holiday_calendar) }

    let!(:holiday1) { create(:event, holiday_calendar: holiday_calendar1, start: ago(6), end: ago(5)) }
    let!(:holiday2) { create(:event, holiday_calendar: holiday_calendar2, start: ago(3), end: ago(2)) }
    let!(:holiday3) { create(:event, holiday_calendar: holiday_calendar2, start: ago(8), end: ago(7)) }

    let!(:calendar1) { create(:calendar, customer: customer1, country: holiday_calendar1.country) }
    let!(:calendar2) { create(:calendar, customer: customer1, country: holiday_calendar2.country) }
    let!(:calendar3) { create(:calendar, customer: customer1, country: holiday_calendar1.country) }
    let!(:calendar4) { create(:calendar, customer: customer2, country: holiday_calendar2.country) }

    let!(:event_1) { create(:event, calendar: calendar1, start: ago(9), end: ago(1)) }
    let!(:event_2) { create(:event, calendar: calendar1, start: ago(5), end: ago(4)) }
    let!(:event_3) { create(:event, calendar: calendar2, start: ago(8), end: ago(7)) }
    let!(:event_4) { create(:event, calendar: calendar3, start: ago(5), end: ago(1)) }
    let!(:event_5) { create(:event, calendar: calendar4, start: ago(5), end: ago(1)) }
    let!(:event_6) { create(:event, calendar: calendar4, start: ago(9), end: ago(1)) }

    context "without the time filter" do
      it "returns an empty array if nothing has been found" do
        params = mash(calendar_ids: "123123123131")
        Event.search(params, customer1).to_a.should == []
      end

      it "returns matched events for a signle calendar" do
        params = mash(calendar_ids: calendar2.id.to_s)
        Event.search(params, customer1).to_a.should == [event_3]
      end

      it "returns matched events for multiple calendars" do
        params = mash(calendar_ids: "#{calendar1.id},#{calendar3.id}")
        Event.search(params, customer1).to_a.should == [event_1, event_2, event_4]
      end
    end

    context "with the time filter" do
      it "returns matched events" do
        params = mash(calendar_ids: "#{calendar1.id},#{calendar2.id}",
          :start => 6.days.ago.to_i, :end => 4.days.ago.to_i)
        Event.search(params, customer1).to_a.should == [event_2]

        params = mash(:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          :start => 5.days.ago.to_i, :end => 1.days.ago.to_i)
        Event.search(params, customer1).to_a.should == [event_2, event_4]

        params = mash(:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
          :start => 9.days.ago.to_i, :end => 1.days.ago.to_i)
        Event.search(params, customer1).to_a.should == [event_1, event_2, event_3, event_4]

        params = mash(:calendar_ids => "#{calendar2.id},#{calendar3.id}",
          :start => 8.days.ago.to_i, :end => 6.days.ago.to_i)
        Event.search(params, customer1).to_a.should == [event_3]
      end
    end

    context "holidays" do
      context "without the time filter" do
        it "returns the holidays along with the events for single calendar" do
          params = mash(calendar_ids: calendar2.id.to_s, holidays: true)
          Event.search(params, customer1).to_a.sort.should == [event_3, holiday2, holiday3].sort
        end

        it "returns the holidays along with the events for multiple calendars" do
          params = mash(calendar_ids: "#{calendar1.id},#{calendar3.id}", holidays: true)
          Event.search(params, customer1).to_a.sort.should == 
            [event_1, event_2, event_4, holiday1].sort

          params = mash(calendar_ids: 
            "#{calendar1.id},#{calendar2.id},#{calendar3.id},#{calendar4.id}", holidays: true)
          Event.search(params, customer1).to_a.sort.should == 
            [calendar1, calendar2, calendar3].map { |c| c.events + c.holidays }.flatten.uniq.sort

          params = mash(calendar_ids: 
            "#{calendar2.id},#{calendar3.id},#{calendar4.id}", holidays: true)
          Event.search(params, customer1).to_a.sort.should == 
            [calendar2, calendar3].map { |c| c.events + c.holidays }.flatten.uniq.sort
        end
      end

      context "with the time filter" do
        it "returns the holidays along with the events in a specified time range" do
          params = mash(calendar_ids: "#{calendar1.id},#{calendar2.id}",
            :start => 6.days.ago.to_i, :end => 4.days.ago.to_i, holidays: true)
          Event.search(params, customer1).to_a.sort.should == [event_2, holiday1].sort

          params = mash(:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
            :start => 5.days.ago.to_i, :end => 1.days.ago.to_i, holidays: true)
          Event.search(params, customer1).to_a.sort.should == [event_2, event_4, holiday2].sort

          params = mash(:calendar_ids => "#{calendar1.id},#{calendar2.id},#{calendar3.id}",
            :start => 9.days.ago.to_i, :end => 1.days.ago.to_i, holidays: true)
          Event.search(params, customer1).to_a.sort.should == 
            [event_1, event_2, event_3, event_4, holiday1, holiday2, holiday3].sort

          params = mash(:calendar_ids => "#{calendar2.id},#{calendar3.id}",
            :start => 8.days.ago.to_i, :end => 6.days.ago.to_i, holidays: true)
          Event.search(params, customer1).to_a.sort.should == [event_3, holiday3].sort
        end
      end
    end
  end
end

