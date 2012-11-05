class Calendar
  include MongoMapper::Document

  key :title,        String
  key :description,  String
  key :country,      String
  key :owner_id,     ObjectId

  validates_presence_of :title

  attr_accessor :include_holidays
  attr_accessible :country, :title, :description

  many :events
  belongs_to :customer

  scope :for_customer, lambda { |customer| where(:customer_id => customer.id) }

  def serializable_hash(options = {})
    super({:only => ["title", "description", "country"]}.merge(options))
  end

  def is_accessible?(current_user, params = nil)
    current_user.has?(self)
  end

  def with_holidays(params)
    self.include_holidays = params.holidays
    self
  end

  def to_ical
    IcalendarEvents.new(add_holidays(events)).to_ical
  end

  private

  def add_holidays(events)
    events + (self.include_holidays ? Holidays.for_country(self.country) : [])
  end
end

