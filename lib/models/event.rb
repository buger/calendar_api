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

  def serializable_hash(options = {})
    super({:only => ["title", "description", "start", "end", "color"]}.merge(options))
  end

  scope :calendars, lambda { |ids| where(:calendar_id.in => ids) }
  scope :within_time, lambda { |start, end_|
    where(:start.gt => Time.parse(start) - 1.day, :end.lt => Time.parse(end_) + 1.day)
  }

  def self.search(params)
    events = calendars(params[:calendar_ids].split(","))
    events = events.within_time(*params.values_at("start", "end")) if valid_time_attributes?(params)
    events.to_a
  end

  private

  def self.valid_time_attributes?(params)
    params["start"] && params["end"] && params["start"] <= params["end"]
  end
end

