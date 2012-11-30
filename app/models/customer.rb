require "securerandom"

class Customer
  include Mongoid::Document

  field :api_key, type: String

  has_many :calendars, dependent: :delete
  has_many :events

  before_create :generate_api_key

  attr_accessible

  def has?(resource)
    self == resource.customer
  end

  def self.authorize!(api_key)
    Customer.find_by(api_key: api_key)
  end

  index({api_key: 1}, {unique: true})

  private

  def generate_api_key
    self.api_key = SecureRandom.hex
  end
end

