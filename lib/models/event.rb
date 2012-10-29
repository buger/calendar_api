class Event
  include MongoMapper::Document

  key :calendar_id,  ObjectId
  key :title,        String
  key :description,  String

  key :start,        Time
  key :end,          Time

  key :color,        String
  key :owner_id,     ObjectId

  belongs_to :calendar

  validates_presence_of :title

  attr_accessible :title, :description, :start, :end, :color

  def serializable_hash(options = {})
    super({:only => [:title, :description, :start, :end, :color]}.merge(options))
  end

  def start=(time_in_numbers)
    @start = Time.at(time_in_numbers)
  end

  def end=(time_in_numbers)
    instance_variable_set(:@end, Time.at(time_in_numbers))
  end

  scope :calendars, lambda { |ids| 
    where(:calendar_id.in => ids)
  }

  scope :within_time, lambda { |start_at, end_at|
    where(:start.gt => Time.at(start_at) - 1.day, :end.lt => Time.at(end_at) + 1.day)
  }

  def self.search(params)
    events = calendars(params.calendar_ids.split(","))
    events = events.within_time(*params.values_at("start", "end")) if valid_time_range?(params)
    events.to_a
  end

  private

  def self.valid_time_range?(params)
    params.start && params.end # && Time.at(params.start) <= Time.at(params.end)
  end
end

