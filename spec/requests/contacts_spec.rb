require 'rails_helper'

RSpec.describe "Api::Contacts", type: :request do
  describe "POST /api/contacts" do
    it "認証なしでもお問い合わせを作成できる" do
      expect {
        post "/api/contacts", params: {
          contact: {
            name: "テスト太郎",
            email: "test@example.com",
            subject: "テスト件名",
            message: "テストメッセージ"
          }
        }
      }.to change(Contact, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "バリデーションエラーの場合 422 を返す" do
      post "/api/contacts", params: {
        contact: { name: "", email: "", subject: "", message: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "無効なメールアドレスで 422 を返す" do
      post "/api/contacts", params: {
        contact: { name: "太郎", email: "invalid", subject: "件名", message: "本文" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
