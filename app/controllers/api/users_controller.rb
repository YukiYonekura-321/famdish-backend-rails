module Api
  class UsersController < ApplicationController
    before_action :authenticate_user!

    # DELETE /api/users/me
    def destroy_me
      ActiveRecord::Base.transaction do
        # member（+ likes, dislikes, menus が dependent: :destroy で連鎖削除）
        @current_user.member&.destroy!

        # user 本体
        @current_user.destroy!
      end

      head :no_content
    rescue ActiveRecord::RecordNotDestroyed => e
      render json: { error: "退会処理に失敗しました: #{e.message}" }, status: :unprocessable_entity
    end
  end
end
