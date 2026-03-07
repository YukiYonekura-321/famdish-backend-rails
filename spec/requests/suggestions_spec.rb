require 'rails_helper'

RSpec.describe "Api::Suggestions", type: :request do
  let!(:family) { create(:family) }
  let!(:user)   { create(:user, family: family) }
  let!(:member) { create(:member, family: family, user: user) }

  before do
    stub_firebase_auth(user.firebase_uid)
    family.update!(today_cook_id: member.id)
  end

  let(:headers) { auth_headers(user) }

  describe "POST /api/suggestions" do
    it "献立提案ジョブをキューに登録する" do
      expect {
        post "/api/suggestions", params: { budget: 1000, cooking_time: 30 }, headers: headers
      }.to have_enqueued_job(SuggestionGenerateJob)

      expect(response).to have_http_status(:accepted)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("pending")
      expect(body["id"]).to be_present
    end

    it "家族がない場合 400 を返す" do
      user_no_family = create(:user)
      stub_firebase_auth(user_no_family.firebase_uid)

      post "/api/suggestions", params: { budget: 1000 }, headers: auth_headers(user_no_family)
      expect(response).to have_http_status(:bad_request)
    end

    it "今日の料理担当でなければ 403 を返す" do
      other_member = create(:member, family: family)
      family.update!(today_cook_id: other_member.id)

      post "/api/suggestions", params: { budget: 1000 }, headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/suggestions/:id" do
    context "ステータスが pending" do
      let!(:suggestion) { create(:suggestion, family: family, proposer: member.id, status: "pending") }

      it "pending ステータスを返す" do
        get "/api/suggestions/#{suggestion.id}", headers: headers
        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)
        expect(body["status"]).to eq("pending")
      end
    end

    context "ステータスが completed" do
      let!(:suggestion) do
        create(:suggestion, family: family, proposer: member.id, status: "completed",
               ai_raw_json: '{"options":[{"dish_name":"カレー"}]}')
      end

      it "AI 結果とともに返す" do
        get "/api/suggestions/#{suggestion.id}", headers: headers

        body = JSON.parse(response.body)
        expect(body["status"]).to eq("completed")
        expect(body["suggest_field"]).to be_present
      end
    end

    context "ステータスが failed" do
      let!(:suggestion) { create(:suggestion, family: family, proposer: member.id, status: "failed") }

      it "エラーメッセージを返す" do
        get "/api/suggestions/#{suggestion.id}", headers: headers

        body = JSON.parse(response.body)
        expect(body["status"]).to eq("failed")
        expect(body["error"]).to eq("AI生成に失敗しました")
      end
    end
  end

  describe "POST /api/suggestions/:id/feedback" do
    let!(:suggestion) { create(:suggestion, family: family, proposer: member.id, status: "completed", ai_raw_json: '{}') }

    it "フィードバックを保存する" do
      post "/api/suggestions/#{suggestion.id}/feedback",
           params: { chosenOption: "A", feedbackNote: "もっと辛いのが良い" },
           headers: headers

      expect(response).to have_http_status(:no_content)
      suggestion.reload
      expect(suggestion.chosen_option).to eq("A")
      expect(suggestion.feedback).to eq("もっと辛いのが良い")
    end
  end
end
