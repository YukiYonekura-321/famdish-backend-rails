module Api
  class InvitationsController < ApplicationController
    before_action :authenticate_user!, only: [:create, :accept]
    before_action :set_valid_invitation, only: [:show, :accept]

    # POST /api/invitations
    def create
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      invitation = family.invitations.create!(expires_at: 7.days.from_now)

      render json: {
        token: invitation.token,
        invite_url: "#{frontend_base_url}/invite/#{invitation.token}",
        expires_at: invitation.expires_at
      }, status: :created
    end

    # GET /api/invitations/:token
    def show
      render json: { valid: true, family_name: @invitation.family.name }, status: :ok
    end

    # POST /api/invitations/:token/accept
    def accept
      if @current_user.family_id.present?
        return render json: { error: "既に家族に所属しています" }, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        @current_user.update!(family: @invitation.family)
        @invitation.mark_as_used!
      end

      render json: {
        message: "招待を受諾しました",
        family_id: @invitation.family.id,
        family_name: @invitation.family.name
      }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    private

    def set_valid_invitation
      @invitation = Invitation.includes(:family).find_by(token: params[:token])
      return render json: { error: "招待が見つかりません" }, status: :not_found unless @invitation
      return render json: { error: "招待が無効または期限切れです" }, status: :unprocessable_entity unless @invitation.valid_invitation?
    end

    def frontend_base_url
      ENV.fetch("FRONTEND_URL", "http://localhost:3000")
    end
  end
end
