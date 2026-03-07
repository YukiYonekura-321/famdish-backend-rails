FactoryBot.define do
  factory :dislike do
    member
    sequence(:name) { |n| "嫌い#{n}" }
  end
end
