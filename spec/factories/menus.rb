FactoryBot.define do
  factory :menu do
    sequence(:name) { |n| "メニュー#{n}" }
    member
  end
end
