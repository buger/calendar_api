require 'icalendar'

class IcalRender
  def initialize(*objects)
    @objects = normalize(objects.flatten)
  end

  def render
    @objects
  end

  private

  def normalize(objects)
    if objects.first.is_a?(Calendar)
      build_ical_from_calendars(objects)
    elsif objects.first.is_a?(Event)
      build_ical_from_events(objects)
    else
      objects.first.to_s
    end
  end

  def build_ical_from_calendars(calendars)
    build_calendar do |builder|
      calendars.each do |calendar|
        add_events(builder, calendar.events)
      end
    end
  end

  def build_ical_from_events(events)
    build_calendar do |builder|
      add_events(builder, events)
    end
  end

  def build_calendar(&block)
    ical_calendar = Icalendar::Calendar.new
    block.call(ical_calendar)
    ical_calendar.to_ical
  end

  def add_events(calendar, events)
    events.each { |e| calendar.add_event(build_event(e)) }
  end

  def build_event(record)
    event = Icalendar::Event.new
    event.dtstart     = record.start
    event.dtend       = record.end
    event.description = record.description
    event.summary     = record.title
    event
  end
end

