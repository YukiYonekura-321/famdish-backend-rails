FactoryBot.define do
  factory :contact do
    name { "テスト太郎" }
    email { "test@example.com" }
    subject { "テスト件名" }
    message { "テストメッセージ" }
  end
end
