require "spec_helper.rb"
require "icalendar"

describe HTMLRender do
  let!(:customer) { create(:customer) }
  let!(:calendar1) { create(:calendar, customer: customer) }
  let!(:calendar2) { create(:calendar, customer: customer) }
  let!(:event1) { create(:event, calendar: calendar1) }
  let!(:event2) { create(:event, calendar: calendar1) }
  let!(:event3) { create(:event, calendar: calendar1) }
  let!(:event4) { create(:event, calendar: calendar2) }
  let!(:event5) { create(:event, calendar: calendar2) }

  subject { HTMLRender }

  it "renders pain text of objects in not Calendar or Event" do
    object = "text 123"
    subject.new(object).instance_variable_get(:@events).should == nil
  end

  it "renders calendar with a single event" do
    subject.new(event1).instance_variable_get(:@events).should == [event1]
  end

  it "renders calendar with multiple events" do
    render = subject.new(event1, event2)
    render.instance_variable_get(:@title).should == event1.calendar.title
    render.instance_variable_get(:@events).should == [event1, event2]
  end

  it "renders calendar with the events of the passed calendar" do
    render = subject.new(calendar1)
    render.instance_variable_get(:@title).should == calendar1.title
    render.instance_variable_get(:@events).should == [event1, event2, event3]
  end

  it "renders calendar with the events of the passsed calendars" do
    events = [event1, event2, event3, event4, event5]
    render = subject.new(calendar1, calendar2)
    render.instance_variable_get(:@title).should == "#{calendar1.title}, #{calendar2.title}"
    render.instance_variable_get(:@events).should == events
  end
end

