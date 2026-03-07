require 'rails_helper'

RSpec.describe "Api::Users", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "DELETE /api/users/me" do
    it "ユーザーとメンバーを削除（退会）できる" do
      expect {
        delete "/api/users/me", headers: headers
      }.to change(User, :count).by(-1)
       .and change(Member, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "likes, dislikes, menus が依存削除される" do
      create(:like, member: member)
      create(:dislike, member: member)
      create(:menu, member: member)

      expect {
        delete "/api/users/me", headers: headers
      }.to change(Like, :count).by(-1)
       .and change(Dislike, :count).by(-1)
       .and change(Menu, :count).by(-1)
    end
  end
end
