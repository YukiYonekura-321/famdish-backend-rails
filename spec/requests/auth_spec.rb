require 'rails_helper'

RSpec.describe "認証", type: :request do
  describe "Firebase 認証" do
    context "トークンなし" do
      it "401 を返す" do
        get "/api/stocks"
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("トークンがありません")
      end
    end

    context "無効なトークン" do
      before { stub_firebase_auth_failure }

      it "401 を返す" do
        get "/api/stocks", headers: { "Authorization" => "Bearer invalid-token" }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("トークンが無効です")
      end
    end

    context "有効なトークン" do
      let!(:user) { create(:user, firebase_uid: "valid-uid") }
      let!(:family) { create(:family) }
      let!(:member) { create(:member, family: family, user: user) }

      before do
        user.update!(family: family)
        stub_firebase_auth("valid-uid")
      end

      it "認証成功し正常にレスポンスを返す" do
        get "/api/stocks", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
      end
    end

    context "証明書エラーからのリカバリ" do
      let!(:user) { create(:user, firebase_uid: "recover-uid") }
      let!(:family) { create(:family) }
      let!(:member) { create(:member, family: family, user: user) }

      before { user.update!(family: family) }

      it "NoCertificatesError 時に証明書を再取得して認証成功する" do
        call_count = 0
        allow(FirebaseIdToken::Signature).to receive(:verify) do
          call_count += 1
          if call_count == 1
            raise FirebaseIdToken::Exceptions::NoCertificatesError
          else
            { "user_id" => "recover-uid" }
          end
        end
        allow(FirebaseIdToken::Certificates).to receive(:request!)

        get "/api/stocks", headers: { "Authorization" => "Bearer some-token" }
        expect(response).to have_http_status(:ok)
        expect(FirebaseIdToken::Certificates).to have_received(:request!)
      end

      it "CertificateExpiredError 時に証明書を再取得して認証成功する" do
        call_count = 0
        allow(FirebaseIdToken::Signature).to receive(:verify) do
          call_count += 1
          if call_count == 1
            raise FirebaseIdToken::Exceptions::CertificateExpiredError
          else
            { "user_id" => "recover-uid" }
          end
        end
        allow(FirebaseIdToken::Certificates).to receive(:request!)

        get "/api/stocks", headers: { "Authorization" => "Bearer some-token" }
        expect(response).to have_http_status(:ok)
        expect(FirebaseIdToken::Certificates).to have_received(:request!)
      end
    end

    context "予期しない認証エラー" do
      it "一般的な例外で nil を返し 401 になる" do
        allow(FirebaseIdToken::Signature).to receive(:verify)
          .and_raise(StandardError, "unexpected error")
        allow(FirebaseIdToken::Certificates).to receive(:request!)

        get "/api/stocks", headers: { "Authorization" => "Bearer some-token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
