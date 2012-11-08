class Event
  include MongoMapper::Document

  key :calendar_id,  ObjectId
  key :title,        String
  key :description,  String

  key :dtstart,      Time
  key :dtend,        Time

  key :color,        String
  key :customer_id,  ObjectId

  belongs_to :calendar
  belongs_to :customer

  validates_presence_of :title

  attr_accessible :title, :description, :start, :end, :color

  before_save do
    self.customer = calendar.customer
  end

  def serializable_hash(options = {})
    super({:only => [:title, :description, :dtstart, :dtend, :color]}.merge(options))
  end

  def start=(time_in_numbers)
    @dtstart = Time.at(time_in_numbers)
  end

  def end=(time_in_numbers)
    @dtend = Time.at(time_in_numbers)
  end

  def dtstart
    @dtstart.utc
  end

  def dtend
    @dtend.utc
  end

  scope :for_customer, lambda { |customer|
    where(:customer_id => customer.id.to_s)
  }

  scope :calendars, lambda { |ids|
    where(:calendar_id.in => ids)
  }

  scope :within_time, lambda { |dtstart, dtend|
    where(:dtstart.gt => Time.at(dtstart) - 1.day, :dtend.lt => Time.at(dtend) + 1.day)
  }

  def self.search(params, customer)
    events = for_customer(customer)
    events = events.calendars(params.calendar_ids.split(","))
    events = events.within_time(*params.values_at("start", "end")) if valid_time_range?(params)
    IcalendarEvents.new(events)
  end

  def is_accessible?(current_user, params)
    current_user.has?(self) && calendar_id.to_s == params.calendar_ids
  end

  def to_ical
    IcalendarEvent.new(self).to_ical
  end

  private

  def self.valid_time_range?(params)
    params.start && params.end
  end
end

