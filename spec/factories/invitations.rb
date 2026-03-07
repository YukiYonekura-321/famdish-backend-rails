FactoryBot.define do
  factory :invitation do
    family
    expires_at { 7.days.from_now }
    used { false }
  end
end
