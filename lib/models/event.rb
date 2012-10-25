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
end

