FactoryBot.define do
  factory :good do
    user_id { nil }
    menu_id { nil }
    suggestion_id { nil }

    trait :for_menu do
      association :menu_ref, factory: :menu
      menu_id { menu_ref.id }
    end

    trait :for_suggestion do
      association :suggestion_ref, factory: :suggestion
      suggestion_id { suggestion_ref.id }
    end
  end
end
