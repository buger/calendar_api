class HolidayCalendar
  include Mongoid::Document

  field :country, type: String

  validates_presence_of :country

  # belongs_to :customer
  has_many :calendars
  has_many :events, dependent: :delete

  index({country: 1}, {unique: true})
end

