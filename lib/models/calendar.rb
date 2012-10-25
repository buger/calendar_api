class Calendar
  include MongoMapper::Document

  key :title,        String
  key :description,  String
  key :owner_id,     ObjectId

  validates_presence_of :title

  many :events
end

