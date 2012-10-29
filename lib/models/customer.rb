class Customer
  include MongoMapper::Document

  key :api_key, String

  many :calendars, :foreign_key => :owner_id
end
