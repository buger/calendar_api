class Event
  include Mongoid::Document

  field :title,        type: String
  field :description,  type: String

  field :start,        type: Time
  field :end,          type: Time

  field :color,        type: String

  belongs_to :calendar, index: true
  belongs_to :customer
  belongs_to :holiday_calendar

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
    send(:in, {calendar_id: ids})
  }

  scope :within_time, lambda { |start_at, end_at|
    where(:start.gt => Time.at(start_at) - 1.day, :end.lt => Time.at(end_at) + 1.day)
  }

  def self.search(params, customer)
    events = for_customer(customer)
    events = events.calendars(params.calendar_ids.split(","))
    events = events.within_time(*params.values_at("start", "end")) if params.start && params.end
    events
  end

  def is_accessible?(current_user, params)
    current_user.has?(self) && calendar_id.to_s == params.calendar_ids
  end

  private

  def js_timestamp(time)
    time.utc.to_i * 1000
  end
end

