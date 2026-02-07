FirebaseIdToken.configure do |config|
  # config.redis = Redis.new(url: ENV["REDIS_URL"])
  uri = URI.parse(ENV["REDIS_URL"])

  config.redis = Redis.new(
    url: ENV["REDIS_URL"],
    ssl: uri.scheme == "rediss",
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } # ←自己署名対応
  )
  config.project_ids = [ "famdish-6f806" ]  # ← Firebase プロジェクトIDを設定
  # タイムアウトを少し長めに
end

# # 証明書を事前取得してキャッシュ
# begin
#   FirebaseIdToken::Certificates.request
# rescue => e
#   Rails.logger.warn "証明書の取得に失敗しました: #{e.message}"
# end