module Api
  class FamiliesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_family

    # GET /api/families
    # 現在のユーザーの家族情報を取得
    def index
      render json: { today_cook_id: @family.today_cook_id }, status: :ok
    end

    # POST /api/families/assign_cook
    # プルダウンで選んだメンバーを今日の料理担当者に設定する
    def assign_cook
      member = @family.members.find_by(id: params[:member_id])
      return render json: { error: "メンバーが見つかりません" }, status: :not_found unless member

      @family.update!(today_cook_id: member.id)

      render json: {
        today_cook_id: @family.today_cook_id,
        today_cook_name: member.name
      }, status: :ok
    end

    private

    def set_family
      @family = @current_user.family
      render json: { error: "家族が見つかりません" }, status: :bad_request unless @family
    end
  end
end
