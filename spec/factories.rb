require 'factories/countries'

FactoryGirl.define do
  factory :customer do
  end

  factory :calendar do
    sequence(:country) { Countries.sample }
    sequence(:description) { |n| "Description #{n}" }
    sequence(:title) { |n| "Calendar #{n}" }

    customer
    holiday_calendar
  end

  factory :holiday_calendar do
    sequence(:country) { Countries.sample }
  end

  start_at = proc { rand(11..20).days.ago.to_i }
  end_at   = proc { rand(1..10).days.ago.to_i }

  factory :event do
    sequence(:title) { |n| "Event #{n}" }

    sequence(:start) { start_at.call }
    sequence(:end)   { start_at.call }
  end
end

