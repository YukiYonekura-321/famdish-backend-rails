FactoryBot.define do
  factory :family do
    sequence(:name) { |n| "テスト家族#{n}" }
    today_cook { nil }
  end
end
