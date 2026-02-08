module Api
  class InvitationsController < ApplicationController
    # create と accept は認証必須、show は認証不要（招待確認のみ）
    before_action :authenticate_user!, only: [:create, :accept]

    # POST /api/invitations
    # 招待リンク生成（家族オーナー用）
    def create
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      # 有効期限は7日後（必要に応じて調整）
      invitation = family.invitations.create!(
        expires_at: 7.days.from_now
      )

      # フロントエンド用の招待 URL を生成（環境変数で切り替え推奨）
      base_url = ENV.fetch("FRONTEND_URL", "http://localhost:3000")
      invite_url = "#{base_url}/invite/#{invitation.token}"

      render json: {
        token: invitation.token,
        invite_url: invite_url,
        expires_at: invitation.expires_at
      }, status: :created
    end

    # GET /api/invitations/:token
    # 招待確認（認証不要）
    def show
      invitation = Invitation.includes(:family).find_by(token: params[:token])

      if invitation.nil?
        return render json: { valid: false, error: "招待が見つかりません" }, status: :not_found
      end

      if !invitation.valid_invitation?
        return render json: { valid: false, error: "招待が無効または期限切れです" }, status: :unprocessable_entity
      end

      render json: {
        valid: true,
        family_name: invitation.family.name
      }, status: :ok
    end

    # POST /api/invitations/:token/accept
    # 招待受諾（認証必須）
    def accept
      invitation = Invitation.includes(:family).find_by(token: params[:token])

      # 招待が存在しない
      if invitation.nil?
        return render json: { error: "招待が見つかりません" }, status: :not_found
      end

      # 有効チェック（未使用 & 期限内）
      unless invitation.valid_invitation?
        return render json: { error: "招待が無効または期限切れです" }, status: :unprocessable_entity
      end

      # 既に家族に所属している場合
      if @current_user.family_id.present?
        return render json: { error: "既に家族に所属しています" }, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        # ユーザーを家族に紐付け
        @current_user.update!(family: invitation.family)

        # 招待を使用済みにする
        invitation.mark_as_used!
      end

      render json: {
        message: "招待を受諾しました",
        family_name: invitation.family.name
      }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
