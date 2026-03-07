require 'rails_helper'

RSpec.describe "Api::Likes", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "GET /api/likes" do
    it "家族メンバーの好みを返す" do
      create(:like, member: member, name: "カレー")
      create(:like, member: member, name: "寿司")

      get "/api/likes", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(2)
      expect(body.map { |l| l["name"] }).to contain_exactly("カレー", "寿司")
    end

    it "異なる家族の好みは含まない" do
      # 自分の家族の好み
      create(:like, member: member, name: "カレー")

      # 別の家族のメンバーと好み
      other_family = create(:family)
      other_member = create(:member, family: other_family)
      create(:like, member: other_member, name: "ラーメン")

      get "/api/likes", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["name"]).to eq("カレー")
    end
  end
end
