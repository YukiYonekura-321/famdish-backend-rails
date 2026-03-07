require 'rails_helper'

RSpec.describe "認証", type: :request do
  describe "Firebase 認証" do
    context "トークンなし" do
      it "401 を返す" do
        get "/api/stocks"
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("トークンがありません")
      end
    end

    context "無効なトークン" do
      before { stub_firebase_auth_failure }

      it "401 を返す" do
        get "/api/stocks", headers: { "Authorization" => "Bearer invalid-token" }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("トークンが無効です")
      end
    end

    context "有効なトークン" do
      let!(:user) { create(:user, firebase_uid: "valid-uid") }
      let!(:family) { create(:family) }
      let!(:member) { create(:member, family: family, user: user) }

      before do
        user.update!(family: family)
        stub_firebase_auth("valid-uid")
      end

      it "認証成功し正常にレスポンスを返す" do
        get "/api/stocks", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
