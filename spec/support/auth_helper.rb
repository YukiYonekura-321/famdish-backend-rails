# Firebase 認証をモックするヘルパー
module AuthHelper
  # テスト用デフォルト Firebase UID
  DEFAULT_UID = "test-firebase-uid-123"

  # 認証済みリクエスト用ヘッダーを返す
  def auth_headers(user = nil)
    uid = user&.firebase_uid || DEFAULT_UID
    { "Authorization" => "Bearer fake-token-#{uid}" }
  end

  # 認証モックを有効化（before で呼ぶ）
  def stub_firebase_auth(uid = DEFAULT_UID)
    allow(FirebaseIdToken::Signature).to receive(:verify)
      .and_return({ "user_id" => uid })
    allow(FirebaseIdToken::Certificates).to receive(:request!)
  end

  # 認証失敗を模擬
  def stub_firebase_auth_failure
    allow(FirebaseIdToken::Signature).to receive(:verify).and_return(nil)
    allow(FirebaseIdToken::Certificates).to receive(:request!)
  end
end
