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

  describe "GET /api/members/all" do
    it "全メンバーの id と name を返す" do
      create(:member, family: family, name: "花子")

      get "/api/members/all", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to be >= 2
      expect(body.first.keys).to contain_exactly("id", "name")
    end
  end

  describe "POST /api/members (新規ファミリー作成)" do
    it "新しいメンバーを家族に追加できる" do
      new_user = create(:user)
      stub_firebase_auth(new_user.firebase_uid)

      post "/api/members",
           params: { member: { name: "次郎" }, family_id: family.id, link_user: true },
           headers: auth_headers(new_user)

      expect(response).to have_http_status(:created)
    end

    it "family_id なしで新しい家族を作りメンバーを追加する" do
      new_user = create(:user)
      stub_firebase_auth(new_user.firebase_uid)

      expect {
        post "/api/members",
             params: { member: { name: "新太郎" }, family: { name: "新家族" }, link_user: true },
             headers: auth_headers(new_user)
      }.to change(Family, :count).by(1)
       .and change(Member, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(new_user.reload.family).to be_present
      expect(new_user.family.name).to eq("新家族")
    end

    it "存在しない family_id で 400 を返す" do
      new_user = create(:user)
      stub_firebase_auth(new_user.firebase_uid)

      post "/api/members",
           params: { member: { name: "太郎" }, family_id: 99999, link_user: true },
           headers: auth_headers(new_user)

      expect(response).to have_http_status(:bad_request)
    end

    it "link_user: false でユーザー紐付けなしにメンバーを作成する" do
      post "/api/members",
           params: { member: { name: "子供" }, family_id: family.id, link_user: false },
           headers: headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      new_member = Member.find(body["id"])
      expect(new_member.user_id).to be_nil
    end
  end

  describe "権限チェック" do
    it "他のユーザーに紐づくメンバーの更新は 401" do
      other_user = create(:user, family: family)
      other_member = create(:member, family: family, user: other_user, name: "他人")

      patch "/api/members/#{other_member.id}",
            params: { member: { name: "改変" } },
            headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "別の家族のメンバーの削除は 401" do
      other_family = create(:family)
      other_member = create(:member, family: other_family, name: "別家族")

      delete "/api/members/#{other_member.id}", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "メンバー index（家族なし）" do
    it "家族がないユーザーは空配列を返す" do
      user_no_family = create(:user)
      stub_firebase_auth(user_no_family.firebase_uid)

      get "/api/members", headers: auth_headers(user_no_family)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end
end
