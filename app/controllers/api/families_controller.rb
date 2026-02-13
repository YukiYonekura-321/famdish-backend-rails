module Api
  class FamiliesController < ApplicationController
    before_action :authenticate_user!

    # POST /api/families/assign_cook
    # body: { member_id: 5 }
    # プルダウンで選んだメンバーを今日の料理担当者に設定する
    def assign_cook
      Rails.logger.info "assign_cook called with params: #{params.inspect}"
      
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      member = family.members.find_by(id: params[:member_id])
      return render json: { error: "メンバーが見つかりません" }, status: :not_found unless member

      family.update!(today_cook_id: member.id)

      render json: {
        today_cook_id: family.today_cook_id,
        today_cook_name: member.name
      }, status: :ok
    end
  end
end
