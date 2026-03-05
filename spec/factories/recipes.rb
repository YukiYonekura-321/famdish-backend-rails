FactoryBot.define do
  factory :recipe do
    sequence(:dish_name) { |n| "テスト料理#{n}" }
    servings { 2 }
    cooking_time { 30 }
    missing_ingredients { [{ "name" => "玉ねぎ", "quantity" => "1個" }] }
    steps { [{ "step" => 1, "description" => "材料を切る" }] }
    reason { "おいしいから" }
    family { nil }
    suggestion { nil }
  end
end
