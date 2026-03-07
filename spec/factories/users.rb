FactoryBot.define do
  factory :user do
    sequence(:firebase_uid) { |n| "firebase-uid-#{n}" }
    family { nil }
  end
end
