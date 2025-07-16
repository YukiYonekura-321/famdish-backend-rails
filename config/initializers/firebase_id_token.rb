FirebaseIdToken.configure do |config|
  config.redis = Redis.new
  config.project_ids = [ "famdish-6f806" ]  # ← Firebase プロジェクトIDを設定
end

# 証明書を事前取得してキャッシュ
begin
  FirebaseIdToken::Certificates.request!
rescue => e
  Rails.logger.warn "証明書の取得に失敗しました: #{e.message}"
end