require "spec_helper.rb"
require "icalendar"

describe IcalRender do
  let!(:customer) { create(:customer) }
  let!(:calendar1) { create(:calendar, customer: customer) }
  let!(:calendar2) { create(:calendar, customer: customer) }
  let!(:event1) { create(:event, calendar: calendar1) }
  let!(:event2) { create(:event, calendar: calendar1) }
  let!(:event3) { create(:event, calendar: calendar1) }
  let!(:event4) { create(:event, calendar: calendar2) }
  let!(:event5) { create(:event, calendar: calendar2) }

  subject { IcalRender }

  it "renders plain text if objects is not Calendar or Event" do
    object = "text 123"
    subject.new(object).render.should == "text 123"
  end

  it "renders calendar with a single event" do
    subject.new(event1).render.should contain_objects(:ical, event1)
  end

  it "renders calendar with multiple events" do
    subject.new(event1, event2).render.should contain_objects(:ical, event1, event2)
  end

  it "renders calendar with the events of the passed calendar" do
    subject.new(calendar1).render.should contain_objects(:ical, event1, event2, event3)
  end

  it "renders calendar with the events of the passsed calendars" do
    events = [event1, event2, event3, event4, event5]
    subject.new(calendar1, calendar2).render.should contain_objects(:ical, *events)
  end
end

