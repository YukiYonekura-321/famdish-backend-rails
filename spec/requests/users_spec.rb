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

    it "削除に失敗した場合 422 を返す" do
      allow_any_instance_of(Member).to receive(:destroy!).and_raise(
        ActiveRecord::RecordNotDestroyed.new("削除できません", member)
      )

      delete "/api/users/me", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)

      body = JSON.parse(response.body)
      expect(body["error"]).to include("退会処理に失敗しました")
    end
  end
end
