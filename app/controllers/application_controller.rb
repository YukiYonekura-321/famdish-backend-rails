class ApplicationController < ActionController::API
  # 認証を行うメソッド。認証が必要なAPIエンドポイントで before_action :authenticate_user! のように使います。
  def authenticate_user!
    # split(" ") で分割して最後の部分（トークン）を取り出します。&. は安全な呼び出し（nilでもエラーにならない）
    token = request.headers["Authorization"]&.split(" ")&.last
    # google-id-token ライブラリを使って、FirebaseのIDトークンを検証
    # ENV['FIREBASE_CLIENT_ID'] は、FirebaseプロジェクトのクライアントID（環境変数で設定）
    # トークンが有効なら、ユーザー情報（user_id など）を含む payload が返却
    payload = GoogleIDToken::Validator.new.check(token, ENV["FIREBASE_CLIENT_ID"])
    # トークンに含まれる user_id を使って、ユーザーを検索。存在しなければ新しく作成。(p.171)
    # @current_user に代入して、後続の処理で使えるようにします。
    @current_user = User.find_or_create_by(firebase_uid: payload["user_id"])
  rescue
    # トークンが無効だったり、検証に失敗した場合は例外が発生。その場合は、HTTPステータス 401 Unauthorized を返します。
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
