FirebaseIdToken.configure do |config|
  config.redis = Redis.new
  config.project_ids = [ "famdish-6f806" ]  # ← Firebase プロジェクトIDを設定
end
