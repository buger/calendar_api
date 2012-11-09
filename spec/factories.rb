require 'securerandom'
require 'factories/countries'

FactoryGirl.define do
  factory :calendar do
    sequence(:country) { Countries.sample }
    sequence(:title) { |n| "title #{n}" }
    
    customer
  end

  start_at = proc { rand(11..20).days.ago.to_i }
  end_at   = proc { rand(1..10).days.ago.to_i }

  factory :event do
    sequence(:title) { |n| "title #{n}" }

    sequence(:start) { start_at.call }
    sequence(:end)   { start_at.call }

    calendar
  end

  factory :customer do
    sequence(:api_key) { SecureRandom.hex }
  end
end

