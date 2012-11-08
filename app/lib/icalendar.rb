require 'icalendar'

class IcalendarEvents
  include Icalendar

  def initialize(events)
    @events   = events
    @calendar = Calendar.new
    @events.each do |event|
      @calendar.add_event(IcalendarEvent.new(event).to_event)
    end
  end

  delegate :any?, :to => :@events
  delegate :to_a, :to => :@events
  delegate :to_ical, :to => :@calendar

  def to_json
    to_a.to_json
  end
end

class IcalendarEvent
  include Icalendar

  def initialize(record)
    @event = Event.new
    @event.start       = parse_date(record.dtstart)
    @event.end         = parse_date(record.dtend)
    @event.description = record.description
    @event.summary     = record.title
  end

  delegate :to_ical, :to => :@event

  def to_event
    @event
  end

  private

  def parse_date(date)
    DateTime.parse(Time.at(date).to_s)
  end
end

