require 'rails_helper'

RSpec.describe "Api::Stocks", type: :request do
  let!(:family)  { create(:family) }
  let!(:user)    { create(:user, family: family) }
  let!(:member)  { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "GET /api/stocks" do
    it "在庫一覧を返す" do
      stock = create(:stock, family: family, name: "にんじん", quantity: 3, unit: "本")

      get "/api/stocks", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["name"]).to eq("にんじん")
      expect(body.first["quantity"]).to eq(3.0)
    end

    it "家族がない場合 400 を返す" do
      user_no_family = create(:user)
      stub_firebase_auth(user_no_family.firebase_uid)

      get "/api/stocks", headers: auth_headers(user_no_family)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/stocks" do
    let(:valid_params) { { stock: { name: "牛乳", quantity: 1, unit: "L" } } }

    it "在庫を作成できる" do
      expect {
        post "/api/stocks", params: valid_params, headers: headers
      }.to change(Stock, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("牛乳")
    end

    it "名前が空の場合 422 を返す" do
      post "/api/stocks", params: { stock: { name: "", quantity: 1, unit: "個" } }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/stocks/:id" do
    let!(:stock) { create(:stock, family: family, name: "卵", quantity: 6, unit: "個") }

    it "在庫を更新できる" do
      patch "/api/stocks/#{stock.id}", params: { stock: { quantity: 10 } }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(stock.reload.quantity.to_f).to eq(10.0)
    end

    it "他の家族の在庫は 404" do
      other_family = create(:family)
      other_stock = create(:stock, family: other_family)

      patch "/api/stocks/#{other_stock.id}", params: { stock: { quantity: 5 } }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/stocks/:id" do
    let!(:stock) { create(:stock, family: family) }

    it "在庫を削除できる" do
      expect {
        delete "/api/stocks/#{stock.id}", headers: headers
      }.to change(Stock, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
