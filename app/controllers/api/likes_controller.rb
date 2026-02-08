module Api
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      family = @current_user.family
      return render json: [], status: :ok unless family

      # family に属するメンバーの likes を取得（N+1 回避で member を preload）
      likes = Like.joins(:member).where(members: { family_id: family.id }).includes(:member)

      render json: likes.as_json(
        only: [:id, :name],
        include: { member: { only: [:id, :name] } }
      ), status: :ok
    end
  end
end