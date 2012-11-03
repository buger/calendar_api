class Calendar
  include MongoMapper::Document

  key :title,        String
  key :description,  String
  key :owner_id,     ObjectId

  validates_presence_of :title

  attr_accessible :title, :description

  many :events
  belongs_to :customer

  scope :for_customer, lambda { |customer| where(:customer_id => customer.id) }

  def serializable_hash(options = {})
    super({:only => ["title", "description"]}.merge(options))
  end

  def is_accessible?(current_user, params = nil)
    current_user.has?(self)
  end

  def to_ical
    IcalendarEvents.new(self.events).to_ical
  end
end

