require "spec_helper.rb"

describe Calendar do
  context "Holidays" do
    let!(:customer) { create(:customer) }
    let!(:calendar) { create(:calendar, customer: customer) }
    let!(:calendar2) { create(:calendar, customer: customer) }

    it "returns ical with the holidays" do
      calendar.with_holidays(mash(holidays: true))
      calendar2.with_holidays(mash(holidays: true))
      calendar.to_ical.should contain_objects(:ical, *holidays_for(calendar))
    end

    it "returns ical with the holidays and events" do
      event1 = create(:event, calendar: calendar)
      event2 = create(:event, calendar: calendar)

      calendar.to_ical.should contain_objects(:ical, event1, event2)

      calendar.with_holidays(mash(holidays: true))
      calendar.to_ical.should contain_objects(:ical, event1, event2, *holidays_for(calendar))
    end
  end
end

