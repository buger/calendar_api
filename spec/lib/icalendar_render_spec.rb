require "spec_helper.rb"
require "icalendar"

describe IcalendarRender do
  let!(:customer) { create(:customer) }
  let!(:calendar) { create(:calendar, customer: customer) }

  it "converts events to .ical calendar" do
    event1 = create(:event, calendar: calendar)
    event2 = create(:event, calendar: calendar)

    ical = IcalendarRender.new(event1, event2).to_ical
    events = Icalendar.parse(ical)[0].events

    events.size.should == 2
    
    times1 = events.map { |x| [x.dtstart.to_i, x.dtend.to_i] }.sort
    times2 = [event1, event2].map { |x| [x.start, x.end] }.sort

    times1.should == times2
  end
end

