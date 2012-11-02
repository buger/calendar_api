require "securerandom"

class Customer
  include MongoMapper::Document

  key :api_key, String

  many :calendars

  before_validation do
    self.api_key = SecureRandom.hex
  end

  validates_uniqueness_of :api_key

  def has?(resource)
    self == resource.customer
  end

  def self.authorize!(api_key)
    Customer.find_by_api_key(api_key)
  end
end

Customer.ensure_index(:api_key)

