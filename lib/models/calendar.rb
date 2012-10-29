class Calendar
  include MongoMapper::Document

  key :title,        String
  key :description,  String
  key :owner_id,     ObjectId

  validates_presence_of :title

  attr_accessible :title, :description

  many :events
  belongs_to :customer

  def serializable_hash(options = {})
    super({:only => ["title", "description"]}.merge(options))
  end
end

