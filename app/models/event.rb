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

  scope :for_customer, ->(customer) { where(customer_id: customer.id.to_s) }

  scope :calendars, ->(ids) { self.in(calendar_id: ids) }

  scope :holidays, ->(ids) { self.in(holiday_calendar_id: ids) }

  scope :within_time, lambda { |start_at, end_at|
    where(:start.gt => Time.at(start_at) - 1.day, :end.lt => Time.at(end_at) + 1.day)
  }

  def self.search(params, customer)
    if params.holidays
      calendar_ids = calendar_ids(params, customer)
      
      events   = events_for_calendars(calendar_ids, params)
      holidays = holidays_for_calendars(Calendar.holidays_for_calendars(calendar_ids), params)

      events + holidays 
    else
      events_for_calendars(calendar_ids(params, customer), params)
    end
  end

  def is_accessible?(current_user, params)
    current_user.has?(self) && calendar_id.to_s == params.calendar_ids
  end

  private

  def js_timestamp(time)
    time.utc.to_i * 1000
  end

  class << self
    def events_for_calendars(calendar_ids, params)
      apply_time_range(calendars(calendar_ids), params).to_a
    end

    def holidays_for_calendars(holidays_ids, params)
      apply_time_range(holidays(holidays_ids), params).to_a
    end

    def apply_time_range(objects, params)
      return objects unless params.start && params.end
      objects.within_time(*params.values_at("start", "end")) 
    end

    def calendar_ids(params, customer)
      params.calendar_ids.split(",") & customer.calendars.map { |o| o.id.to_s }
    end
  end
end

