FactoryBot.define do
  factory :member do
    sequence(:name) { |n| "メンバー#{n}" }
    family
    user { nil }
  end
end
