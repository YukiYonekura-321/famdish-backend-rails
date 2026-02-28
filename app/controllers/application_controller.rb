class ApplicationController < ActionController::API
  before_action :authenticate_user!
  before_action :set_default_format

  private

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end

  def authenticate_user!
    token = extract_token
    return render_unauthorized("トークンがありません") unless token

    verified_token = verify_firebase_token(token)
    return render_unauthorized("トークンが無効です") unless verified_token

    @current_user = User.find_or_create_by(firebase_uid: verified_token["user_id"])
  end

  def extract_token
    request.headers["Authorization"]&.split(" ")&.last
  end

  def verify_firebase_token(token)
    FirebaseIdToken::Signature.verify(token)
  rescue FirebaseIdToken::Exceptions::NoCertificatesError,
         FirebaseIdToken::Exceptions::CertificateExpiredError
    FirebaseIdToken::Certificates.request!
    FirebaseIdToken::Signature.verify(token)
  rescue => e
    Rails.logger.error "認証エラー: #{e.message}"
    nil
  end

  def set_default_format
    request.format = :json
  end
end
