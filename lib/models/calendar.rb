class Calendar
  include MongoMapper::Document

  key :title,        String
  key :description,  String
  key :owner_id,     ObjectId
end

