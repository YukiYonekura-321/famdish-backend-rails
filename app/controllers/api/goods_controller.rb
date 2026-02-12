module Api
  class GoodsController < ApplicationController
    before_action :authenticate_user!

    # GET /api/goods/check?menu_id=123
    # フロントエンドが現在のユーザーと menu_id の組み合わせが Good テーブルに存在するか確認する
    def check
      menu_id = params[:menu_id]
      return render json: { error: "menu_id が必要です" }, status: :bad_request unless menu_id.present?

      good = Good.find_by(user_id: @current_user.id, menu_id: menu_id)
      render json: {
        exists: good.present?,
        good: good ? { id: good.id } : nil
      }, status: :ok
    end

    # GET /api/goods/:id/count or /api/goods/count?menu_id=1
    # 指定したメニューのいいね数を返す
    def count
      menu_id = params[:id] || params[:menu_id]
      return render json: { error: "menu_id が必要です" }, status: :bad_request unless menu_id.present?

      count = Good.where(menu_id: menu_id).count
      render json: { menu_id: menu_id.to_i, count: count }, status: :ok
    end

    # POST /api/goods
    # body: { good: { menu_id: 1 } }
    def create
      menu_id = params.dig(:good, :menu_id) || params[:menu_id]
      return render json: { error: "menu_id が必要です" }, status: :bad_request unless menu_id.present?

      # 既に存在する場合はそれを返す
      good = Good.find_by(user_id: @current_user.id, menu_id: menu_id)
      if good
        return render json: { id: good.id }, status: :ok
      end

      good = Good.create!(user_id: @current_user.id, menu_id: menu_id)
      render json: { id: good.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    # DELETE /api/goods/:id
    def destroy
      good = Good.find_by(id: params[:id], user_id: @current_user.id)
      return render json: { error: "権限がありません" }, status: :unauthorized unless good

      good.destroy
      head :no_content
    end
  end
end