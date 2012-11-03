class Event
  include MongoMapper::Document

  key :calendar_id,  ObjectId
  key :title,        String
  key :description,  String

  key :start,        Time
  key :end,          Time

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
    super({:only => [:title, :description, :start, :end, :color]}.merge(options))
  end

  def start=(time_in_numbers)
    @start = Time.at(time_in_numbers)
  end

  def end=(time_in_numbers)
    instance_variable_set(:@end, Time.at(time_in_numbers))
  end

  scope :for_customer, lambda { |customer|
    where(:customer_id => customer.id.to_s)
  }

  scope :calendars, lambda { |ids|
    where(:calendar_id.in => ids)
  }

  scope :within_time, lambda { |start_at, end_at|
    where(:start.gt => Time.at(start_at) - 1.day, :end.lt => Time.at(end_at) + 1.day)
  }

  def self.search(params, customer)
    events = for_customer(customer)
    events = events.calendars(params.calendar_ids.split(","))
    events = events.within_time(*params.values_at("start", "end")) if valid_time_range?(params)
    events.to_a
  end

  def is_accessible?(current_user, params)
    current_user.has?(self) && calendar_id.to_s == params.calendar_ids
  end

  def to_ical
    IcalendarAPI.new(self).to_ical
  end

  private

  def self.valid_time_range?(params)
    params.start && params.end
  end
end

