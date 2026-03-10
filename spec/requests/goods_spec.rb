require 'rails_helper'

RSpec.describe "Api::Goods", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "GET /api/goods/check" do
    it "menu_id の Good 存在チェック" do
      menu = create(:menu, member: member)
      Good.create!(user_id: user.id, menu_id: menu.id)

      get "/api/goods/check", params: { menu_id: menu.id }, headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["exists"]).to be true
    end

    it "Good が存在しない場合 exists: false" do
      get "/api/goods/check", params: { menu_id: 99999 }, headers: headers
      body = JSON.parse(response.body)
      expect(body["exists"]).to be false
    end
  end

  describe "GET /api/goods/count" do
    it "menu_id の Good 件数を返す" do
      menu = create(:menu, member: member)
      Good.create!(user_id: user.id, menu_id: menu.id)

      get "/api/goods/count", params: { menu_id: menu.id }, headers: headers

      body = JSON.parse(response.body)
      expect(body["count"]).to eq(1)
    end
  end

  describe "POST /api/goods" do
    it "menu 用の Good を作成できる" do
      menu = create(:menu, member: member)

      expect {
        post "/api/goods", params: { menu_id: menu.id }, headers: headers
      }.to change(Good, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "既に Good がある場合は 200 を返す（重複しない）" do
      menu = create(:menu, member: member)
      Good.create!(user_id: user.id, menu_id: menu.id)

      expect {
        post "/api/goods", params: { menu_id: menu.id }, headers: headers
      }.not_to change(Good, :count)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/goods/:id" do
    it "Good を削除できる" do
      menu = create(:menu, member: member)
      good = Good.create!(user_id: user.id, menu_id: menu.id)

      expect {
        delete "/api/goods/#{good.id}", headers: headers
      }.to change(Good, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "他のユーザーの Good は削除できない" do
      other_user = create(:user)
      menu = create(:menu, member: member)
      good = Good.create!(user_id: other_user.id, menu_id: menu.id)

      delete "/api/goods/#{good.id}", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Suggestion 用 Good" do
    let!(:suggestion) do
      create(:suggestion, family: family, proposer: member.id, status: "completed", ai_raw_json: '{}')
    end

    it "GET /api/goods/check_suggestion が動作する" do
      Good.create!(user_id: user.id, suggestion_id: suggestion.id)

      get "/api/goods/check_suggestion", params: { suggestion_id: suggestion.id }, headers: headers

      body = JSON.parse(response.body)
      expect(body["exists"]).to be true
    end

    it "GET /api/goods/count_suggestion で件数を返す" do
      Good.create!(user_id: user.id, suggestion_id: suggestion.id)
      Good.create!(user_id: create(:user).id, suggestion_id: suggestion.id)

      get "/api/goods/count_suggestion", params: { suggestion_id: suggestion.id }, headers: headers

      body = JSON.parse(response.body)
      expect(body["count"]).to eq(2)
    end

    it "POST /api/goods/create_suggestion で作成できる" do
      expect {
        post "/api/goods/create_suggestion", params: { suggestion_id: suggestion.id }, headers: headers
      }.to change(Good, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "POST /api/goods/create_suggestion で重複時は既存を返す" do
      Good.create!(user_id: user.id, suggestion_id: suggestion.id)

      expect {
        post "/api/goods/create_suggestion", params: { suggestion_id: suggestion.id }, headers: headers
      }.not_to change(Good, :count)

      expect(response).to have_http_status(:ok)
    end

    it "DELETE /api/goods/destroy_suggestion/:id で削除できる" do
      good = Good.create!(user_id: user.id, suggestion_id: suggestion.id)

      expect {
        delete "/api/goods/#{good.id}/destroy_suggestion", headers: headers
      }.to change(Good, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "パラメータ不備" do
    it "GET /api/goods/check で menu_id 未指定なら 400" do
      get "/api/goods/check", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "GET /api/goods/count で menu_id 未指定なら 400" do
      get "/api/goods/count", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "POST /api/goods で menu_id 未指定なら 400" do
      post "/api/goods", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "GET /api/goods/check_suggestion で suggestion_id 未指定なら 400" do
      get "/api/goods/check_suggestion", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "GET /api/goods/count_suggestion で suggestion_id 未指定なら 400" do
      get "/api/goods/count_suggestion", headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "POST /api/goods/create_suggestion で suggestion_id 未指定なら 400" do
      post "/api/goods/create_suggestion", headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
