FirebaseIdToken.configure do |config|
  uri = URI.parse(ENV["REDIS_URL"])

  ca_file = "/etc/ssl/certs/ca-certificates.crt"

  config.redis = Redis.new(
    url: ENV["REDIS_URL"],
    ssl: uri.scheme == "rediss",
    ssl_params: { 
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
      ca_file: ca_file
    } 
  )
  config.project_ids = [ "famdish-6f806" ]  # ← Firebase プロジェクトIDを設定
end