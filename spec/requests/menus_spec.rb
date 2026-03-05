require 'rails_helper'

RSpec.describe "Api::Menus", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "GET /api/menus" do
    it "メニュー一覧を返す" do
      Menu.create!(name: "カレー", member: member)

      get "/api/menus", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["name"]).to eq("カレー")
    end
  end

  describe "POST /api/menus" do
    it "メニューを作成できる" do
      expect {
        post "/api/menus", params: { menu: { name: "焼きそば" } }, headers: headers
      }.to change(Menu, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/menus/:id" do
    let!(:menu) { Menu.create!(name: "カレー", member: member) }

    it "メニューを更新できる" do
      patch "/api/menus/#{menu.id}", params: { menu: { name: "シチュー" } }, headers: headers
      expect(response).to have_http_status(:no_content)
      expect(menu.reload.name).to eq("シチュー")
    end
  end

  describe "DELETE /api/menus/:id" do
    let!(:menu) { Menu.create!(name: "テスト", member: member) }

    it "メニューを削除できる" do
      expect {
        delete "/api/menus/#{menu.id}", headers: headers
      }.to change(Menu, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
