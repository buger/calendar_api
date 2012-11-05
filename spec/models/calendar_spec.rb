require "spec_helper.rb"

describe Calendar do
  context "Holidays" do
    let(:customer) { create(:customer) }
    let(:calendar) { create(:calendar, :customer => customer) }

    it "returns ical with the holidays" do
      calendar.with_holidays(Hashie::Mash[:holidays => true])

      Icalendar.parse(calendar.to_ical).first.events.size.should ==
      Holidays.for_country(calendar.country).size
      calendar.to_ical
    end

    it "returns ical with the holidays and events" do
      event1 = create(:event, :calendar => calendar)
      event2 = create(:event, :calendar => calendar)

      calendar
      calendar.to_ical.should contain_events_in_ical(event1, event2)

      calendar.with_holidays(Hashie::Mash[:holidays => true])
      calendar.to_ical.should contain_events_in_ical(event1, event2, Holidays.for_country(calendar.country))
    end
  end
end

