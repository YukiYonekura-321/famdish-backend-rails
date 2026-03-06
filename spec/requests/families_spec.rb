require 'rails_helper'

RSpec.describe "Api::Families", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "GET /api/families" do
    it "today_cook_id を返す" do
      family.update!(today_cook_id: member.id)

      get "/api/families", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["today_cook_id"]).to eq(member.id)
    end
  end

  describe "POST /api/families/assign_cook" do
    it "料理担当者を設定できる" do
      post "/api/families/assign_cook", params: { member_id: member.id }, headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["today_cook_id"]).to eq(member.id)
    end

    it "存在しないメンバーで 404 を返す" do
      post "/api/families/assign_cook", params: { member_id: 99999 }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
