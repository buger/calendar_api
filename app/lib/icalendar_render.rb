require 'icalendar'

class IcalendarRender
  include Icalendar

  def initialize(*events)
    @events = events
    @calendar = Calendar.new
    @events.each do |event|
      @calendar.add_event(ical_event(event))
    end
  end

  delegate :to_ical, to: :@calendar

  private

  def ical_event(record)
    event = Event.new
    event.dtstart     = record.start
    event.dtend       = record.end
    event.description = record.description
    event.summary     = record.title
    event
  end
end

