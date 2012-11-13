class Calendar
  include Mongoid::Document
  include Grape::Entity::DSL

  field :title,        type: String
  field :description,  type: String
  field :country,      type: String

  attr_accessible :country, :title, :description
  entity :country, :title, :description

  validates_presence_of :title
  validates_length_of :title, minimum: 1, maximum: 40
  validates_length_of :description, minimum: 0, maximum: 1000

  belongs_to :customer, index: true
  belongs_to :holiday_calendar
  has_many :events, dependent: :delete

  before_save :assign_holiday_calendar

  def assign_holiday_calendar
    self.holiday_calendar = HolidayCalendar.find_by(country: self.country)
  end

  def holidays
    holiday_calendar.try(:events) || []
  end

  def serializable_hash(options = {})
    super({only: %w(title description country)}.merge(options))
  end

  def is_accessible?(current_user, params = nil)
    current_user.has?(self)
  end

  def to_ical
    IcalendarRender.new(*events).to_ical
  end

  def to_html
    HTMLRender.new(title: title, events: events).to_html
  end
end

