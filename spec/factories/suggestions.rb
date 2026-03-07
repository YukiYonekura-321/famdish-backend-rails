FactoryBot.define do
  factory :suggestion do
    family
    proposer { nil } # member.id を直接指定する
    requests { { "cooking_time" => "30" } }
    status { "pending" }

    trait :completed do
      status { "completed" }
      ai_raw_json { '{"options":[{"dish_name":"カレー"}]}' }
    end

    trait :failed do
      status { "failed" }
    end
  end
end
