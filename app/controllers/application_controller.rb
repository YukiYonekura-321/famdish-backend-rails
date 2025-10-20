class ApplicationController < ActionController::API
  before_action :authenticate_user!
  before_action :set_default_format


  private
  # 認証を行うメソッド。認証が必要なAPIエンドポイントで before_action :authenticate_user! のように使います。
  # def authenticate_user!
  #   # split(" ") で分割して最後の部分（トークン）を取り出します。&. は安全な呼び出し（nilでもエラーにならない）
  #   token = request.headers["Authorization"]&.split(" ")&.last
  #   # google-id-token ライブラリを使って、FirebaseのIDトークンを検証
  #   # ENV['FIREBASE_CLIENT_ID'] は、FirebaseプロジェクトのクライアントID（環境変数で設定）
  #   # トークンが有効なら、ユーザー情報（user_id など）を含む payload が返却
  #   payload = GoogleIDToken::Validator.new.check(token, ENV["FIREBASE_CLIENT_ID"])
  #   # トークンに含まれる user_id を使って、ユーザーを検索。存在しなければ新しく作成。(p.171)
  #   # @current_user に代入して、後続の処理で使えるようにします。
  #   @current_user = User.find_or_create_by(firebase_uid: payload["user_id"])
  # rescue => e
  #   Rails.logger.error "認証エラー: #{e.message}"
  #   render json: { error: "Unauthorized" }, status: :unauthorized
  # end
  #
  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    Rails.logger.info "Authorization Header: #{request.headers['Authorization']}" # ←追加

    return render_unauthorized("トークンがありません") unless token

    begin
      verified_token = FirebaseIdToken::Signature.verify(token)
      Rails.logger.info "Decoded token payload: #{verified_token.inspect}"
      if verified_token
        @current_user = User.find_or_create_by(firebase_uid: verified_token["user_id"])
      else
        render_unauthorized("トークンの検証に失敗しました")
      end
    rescue => e
      Rails.logger.error "認証エラー: #{e.message}"
      render_unauthorized("認証中にエラーが発生しました")
    end
  end

  def set_default_format
    request.format = :json
  end
end



# # Gemfile
# gem 'firebase-admin-sdk'

# # application_controller.rb 例
# require 'firebase_admin'

# class ApplicationController < ActionController::API
#   def authenticate_user!
#     token = request.headers["Authorization"]&.split(" ")&.last
#     return render_unauthorized unless token

#     begin
#       firebase = FirebaseAdmin::Auth.new
#       decoded_token = firebase.verify_id_token(token)
#       firebase_uid = decoded_token['uid']

#       @current_user = User.find_or_create_by(firebase_uid: firebase_uid)
#     rescue => e
#       Rails.logger.error "認証エラー: #{e.message}"
#       render json: { error: "Unauthorized" }, status: :unauthorized
#     end
#   end

#   private

#   def render_unauthorized
#     render json: { error: 'Unauthorized' }, status: :unauthorized
#   end
# end
