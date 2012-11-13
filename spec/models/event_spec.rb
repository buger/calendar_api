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
    let!(:customer1) { create(:customer) }
    let!(:customer2) { create(:customer) }

    let!(:calendar1) { create(:calendar, customer: customer1) }
    let!(:calendar2) { create(:calendar, customer: customer1) }
    let!(:calendar3) { create(:calendar, customer: customer1) }
    let!(:calendar4) { create(:calendar, customer: customer2) }

    let!(:event_1) { create(:event, calendar: calendar1, start: 9.days.ago.to_i, end: 1.day.ago.to_i) }
    let!(:event_2) { create(:event, calendar: calendar1, start: 5.days.ago.to_i, end: 4.day.ago.to_i) }
    let!(:event_3) { create(:event, calendar: calendar2, start: 8.days.ago.to_i, end: 7.day.ago.to_i) }
    let!(:event_4) { create(:event, calendar: calendar3, start: 5.days.ago.to_i, end: 1.day.ago.to_i) }
    let!(:event_5) { create(:event, calendar: calendar4, start: 5.days.ago.to_i, end: 1.day.ago.to_i) }
    let!(:event_6) { create(:event, calendar: calendar4, start: 9.days.ago.to_i, end: 1.day.ago.to_i) }

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
  end
end

