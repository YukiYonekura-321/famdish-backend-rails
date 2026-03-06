FactoryBot.define do
  factory :stock do
    family
    sequence(:name) { |n| "食材#{n}" }
    quantity { 1.0 }
    unit { "個" }
  end
end
