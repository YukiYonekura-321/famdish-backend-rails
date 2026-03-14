module Api
  class LikesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_family

    def index
      return render json: [], status: :ok unless @family

      likes = Like.joins(:member)
                  .where(members: { family_id: @family.id })

      render json: likes.as_json(
        only: [ :id, :name ],
      ), status: :ok
    end

    private

    def set_family
      @family = @current_user.family
    end
  end
end
