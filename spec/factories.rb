FactoryGirl.define do
  factory :calendar do
    sequence(:title) { |n| "title #{n}" }
    sequence(:owner_id) { |n| "id#{n}" }
  end

  start_at = proc { rand(11...20).days.ago.to_i }
  end_at   = proc { rand(1...10).days.ago.to_i }

  factory :event do
    sequence(:title) { |n| "title #{n}" }
    start start_at.call
    send(:end, end_at.call)

    calendar
    sequence(:owner_id) { |n| "id#{n}" }
  end
end

