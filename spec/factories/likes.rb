FactoryBot.define do
  factory :like do
    member
    sequence(:name) { |n| "好き#{n}" }
  end
end
