FirebaseIdToken.configure do |config|
  uri = URI.parse(ENV["REDIS_URL"])

  config.redis = Redis.new(
    url: ENV["REDIS_URL"],
    ssl: uri.scheme == "rediss",
    ssl_params: {
      # Heroku Redis はVPC内通信で、通信自体はSSL
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }
  )
  config.project_ids = [ "famdish-6f806" ]  # ← Firebase プロジェクトIDを設定
end
