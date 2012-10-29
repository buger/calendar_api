require 'digest/sha1'

FactoryGirl.define do
  factory :calendar do
    sequence(:title) { |n| "title #{n}" }
    
    customer
  end

  start_at = proc { rand(11..20).days.ago.to_i }
  end_at   = proc { rand(1..10).days.ago.to_i }

  factory :event do
    sequence(:title) { |n| "title #{n}" }
    start start_at.call
    send(:end, end_at.call)

    calendar
  end

  token = proc { Digest::SHA1.hexdigest Time.now.to_s }

  factory :customer do
    api_key token.call
  end
end

