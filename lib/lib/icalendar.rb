require 'icalendar'

class IcalendarEvents
  include Icalendar

  def initialize(events)
    @calendar = Calendar.new
    events.each do |event|
      @calendar.add_event(IcalendarEvent.new(event).to_event)
    end
  end

  def to_ical
    @calendar.to_ical
  end
end

class IcalendarEvent
  include Icalendar

  def initialize(record)
    @event = Event.new
    @event.start = parse_date(record.start)
    @event.end   = parse_date(record.end)
    @event.description  = record.description
    @event.summary  = record.title
  end

  def to_ical
    @event.to_ical
  end

  def to_event
    @event
  end

  private

  def parse_date(date)
    DateTime.parse(Time.at(date).to_s)
  end
end

