require 'rails_helper'

RSpec.describe "Api::Members", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user, name: "太郎") }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "GET /api/members" do
    it "メンバー一覧を返す" do
      create(:member, family: family, name: "花子")

      get "/api/members", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(2)
    end
  end

  describe "GET /api/members/me" do
    it "自分の情報を返す" do
      get "/api/members/me", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["family_id"]).to eq(family.id)
      expect(body["username"]).to eq("太郎")
    end
  end

  describe "POST /api/members" do
    it "新しいメンバーを家族に追加できる" do
      new_user = create(:user)
      stub_firebase_auth(new_user.firebase_uid)

      post "/api/members",
           params: { member: { name: "次郎" }, family_id: family.id, link_user: true },
           headers: auth_headers(new_user)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/members/:id" do
    it "メンバー情報を更新できる" do
      patch "/api/members/#{member.id}",
            params: { member: { name: "太郎改" } },
            headers: headers

      expect(response).to have_http_status(:no_content)
      expect(member.reload.name).to eq("太郎改")
    end
  end

  describe "DELETE /api/members/:id" do
    it "メンバーを削除できる" do
      other_member = create(:member, family: family)

      expect {
        delete "/api/members/#{other_member.id}", headers: headers
      }.to change(Member, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
