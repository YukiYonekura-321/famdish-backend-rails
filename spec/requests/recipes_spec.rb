require 'rails_helper'

RSpec.describe "Api::Recipes", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before { stub_firebase_auth(user.firebase_uid) }

  let(:headers) { auth_headers(user) }

  describe "GET /api/recipes" do
    it "レシピ一覧を返す" do
      create(:recipe, family: family, dish_name: "カレー")
      create(:recipe, family: family, dish_name: "肉じゃが")

      get "/api/recipes", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(2)
      expect(body.map { |r| r["dish_name"] }).to contain_exactly("カレー", "肉じゃが")
    end
  end

  describe "GET /api/recipes/family" do
    it "自分の家族のレシピのみ返す" do
      create(:recipe, family: family, dish_name: "カレー")
      other_family = create(:family)
      create(:recipe, family: other_family, dish_name: "ラーメン")

      get "/api/recipes/family", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.size).to eq(1)
      expect(body.first["dish_name"]).to eq("カレー")
    end

    it "家族がない場合 400 を返す" do
      user_no_family = create(:user)
      stub_firebase_auth(user_no_family.firebase_uid)

      get "/api/recipes/family", headers: auth_headers(user_no_family)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/recipes" do
    let(:valid_params) do
      {
        dish_name: "カレー",
        servings: 4,
        cooking_time: 60,
        steps: [{ step: 1, description: "材料を切る" }],
        missing_ingredients: [{ name: "じゃがいも", quantity: "2個" }],
        reason: "家族が好き"
      }
    end

    it "レシピを作成できる" do
      expect {
        post "/api/recipes", params: valid_params, headers: headers
      }.to change(Recipe, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["id"]).to be_present
    end

    it "dish_name が空なら 400 を返す" do
      post "/api/recipes", params: { dish_name: "" }, headers: headers
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/recipes/:id" do
    let!(:recipe) { create(:recipe, family: family, dish_name: "カレー", cooking_time: 60) }

    it "レシピ詳細を返す" do
      get "/api/recipes/#{recipe.id}", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["id"]).to eq(recipe.id)
      expect(body["cooking_time"]).to eq(60)
    end

    it "存在しないレシピは 404" do
      get "/api/recipes/99999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/recipes/:id" do
    let!(:recipe) { create(:recipe, family: family, servings: 2) }

    it "レシピを更新できる" do
      patch "/api/recipes/#{recipe.id}", params: { servings: 4 }, headers: headers
      expect(response).to have_http_status(:no_content)
      expect(recipe.reload.servings).to eq(4)
    end
  end

  describe "DELETE /api/recipes/:id" do
    let!(:recipe) { create(:recipe, family: family) }

    it "レシピを削除できる" do
      expect {
        delete "/api/recipes/#{recipe.id}", headers: headers
      }.to change(Recipe, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/recipes/explain" do
    let(:ai_response) do
      {
        "choices" => [{
          "message" => {
            "content" => '{"dish_name":"カレー","servings":2,"missing_ingredients":[],"cooking_time":30,"steps":[{"step":1,"description":"作る"}]}'
          }
        }]
      }
    end

    before do
      client_double = instance_double(OpenAI::Client)
      allow(OpenAI::Client).to receive(:new).and_return(client_double)
      allow(client_double).to receive(:chat).and_return(ai_response)
    end

    it "AI レシピ生成結果を返す（DB保存なし）" do
      expect {
        post "/api/recipes/explain", params: { dish_name: "カレー", servings: 2 }, headers: headers
      }.not_to change(Recipe, :count)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["recipe"]["dish_name"]).to eq("カレー")
    end

    it "dish_name がない場合 400 を返す" do
      post "/api/recipes/explain", params: { servings: 2 }, headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    it "servings がない場合 400 を返す" do
      post "/api/recipes/explain", params: { dish_name: "カレー" }, headers: headers
      expect(response).to have_http_status(:bad_request)
    end

    context "suggestion_id が指定されている場合" do
      let!(:suggestion) do
        create(:suggestion, family: family, proposer: member.id, status: "completed",
               ai_raw_json: '{}', requests: { "cooking_time" => "20" })
      end

      it "suggestion の cooking_time を利用してレシピを生成する" do
        post "/api/recipes/explain",
             params: { dish_name: "カレー", servings: 2, suggestion_id: suggestion.id },
             headers: headers

        expect(response).to have_http_status(:ok)
      end
    end

    context "AI が非 JSON を返す場合" do
      before do
        client_double = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).and_return(client_double)
        allow(client_double).to receive(:chat).and_return(
          { "choices" => [{ "message" => { "content" => "これはJSONではありません" } }] }
        )
      end

      it "生のテキストをそのまま返す" do
        post "/api/recipes/explain",
             params: { dish_name: "カレー", servings: 2 },
             headers: headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["recipe"]).to eq("これはJSONではありません")
      end
    end
  end
end
