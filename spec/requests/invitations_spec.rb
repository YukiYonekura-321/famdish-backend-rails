require 'rails_helper'

RSpec.describe "Api::Invitations", type: :request do
  let!(:family) { create(:family, name: "テスト家族") }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "POST /api/invitations" do
    it "招待リンクを作成できる" do
      expect {
        post "/api/invitations", headers: headers
      }.to change(Invitation, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["invite_url"]).to include(body["token"])
    end

    it "家族がない場合 400 を返す" do
      user_no_family = create(:user)
      stub_firebase_auth(user_no_family.firebase_uid)

      post "/api/invitations", headers: auth_headers(user_no_family)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/invitations/:token" do
    let!(:invitation) { create(:invitation, family: family, expires_at: 7.days.from_now) }

    it "有効な招待情報を返す" do
      get "/api/invitations/#{invitation.token}"
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["valid"]).to be true
      expect(body["family_name"]).to eq("テスト家族")
    end

    it "期限切れの招待は 422 を返す" do
      expired = create(:invitation, family: family, expires_at: 1.day.ago)
      get "/api/invitations/#{expired.token}"
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "存在しないトークンは 404 を返す" do
      get "/api/invitations/nonexistent-token"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/invitations/:token/accept" do
    let!(:invitation) { create(:invitation, family: family, expires_at: 7.days.from_now) }

    it "招待を受諾して家族に参加できる" do
      new_user = create(:user, family: nil)
      stub_firebase_auth(new_user.firebase_uid)

      post "/api/invitations/#{invitation.token}/accept", headers: auth_headers(new_user)
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["family_id"]).to eq(family.id)
      expect(new_user.reload.family).to eq(family)
      expect(invitation.reload.used).to be true
    end

    it "既に家族に所属している場合 422 を返す" do
      post "/api/invitations/#{invitation.token}/accept", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
