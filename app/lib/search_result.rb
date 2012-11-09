class SearchResult
  def initialize(events)
    @events = events
  end

  delegate :any?,    to: :@events
  delegate :to_a,    to: :@events
  delegate :to_json, to: :@events

  def to_html
    # TODO: Create a new (temporary) calendar for array of events from different calendars
    HTMLRender.new(@events).to_html
  end

  def to_ical
    IcalendarRender.new(*@events.to_a).to_ical
  end
end
