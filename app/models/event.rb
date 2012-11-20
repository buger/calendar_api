class Event
  include Mongoid::Document

  field :title,        type: String
  field :description,  type: String

  field :start,        type: Time
  field :end,          type: Time

  field :color,        type: String

  belongs_to :calendar, index: true
  belongs_to :customer, index: true
  belongs_to :holiday_calendar, index: true

  validates_presence_of :title
  validates_length_of :title, minimum: 1, maximum: 40
  validates_length_of :description, minimum: 0, maximum: 1000
  validates_length_of :color, minimum: 0, maximum: 40

  attr_accessible :title, :description, :start, :end, :color

  before_save do
    self.customer = calendar.customer if calendar
  end

  def serializable_hash(options = {})
    super({only: %w(title description start end color)}.merge(options))
  end

  def start
    js_timestamp super
  end

  def end
    js_timestamp super
  end

  scope :for_customer, lambda { |customer|
    where(customer_id: customer.id.to_s)
  }

  scope :calendars, lambda { |ids|
    self.in(calendar_id: ids)
  }

  scope :within_time, lambda { |start_at, end_at|
    where(:start.gt => Time.at(start_at) - 1.day, :end.lt => Time.at(end_at) + 1.day)
  }

  # TODO: Refactor this method
  def self.search(params, customer)
    if params.holidays
      calendar_ids = calendar_ids(params, customer)
      holiday_calendar_ids = Calendar.in(id: calendar_ids).to_a.map { |o| o.holiday_calendar_id.to_s }
      
      events = calendars(calendar_ids)
      events = events.within_time(*params.values_at("start", "end")) if params.start && params.end

      holidays = self.in(holiday_calendar_id: holiday_calendar_ids)
      holidays = holidays.within_time(*params.values_at("start", "end")) if params.start && params.end

      events + holidays 
    else
      events = calendars(calendar_ids(params, customer))
      events = events.within_time(*params.values_at("start", "end")) if params.start && params.end
      events = events.to_a
    end
  end

  def is_accessible?(current_user, params)
    current_user.has?(self) && calendar_id.to_s == params.calendar_ids
  end

  private

  def self.calendar_ids(params, customer)
    params.calendar_ids.split(",") & customer.calendars.map { |o| o.id.to_s }
  end

  def js_timestamp(time)
    time.utc.to_i * 1000
  end
end

