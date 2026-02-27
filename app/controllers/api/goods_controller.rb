module Api
  class GoodsController < ApplicationController
    before_action :authenticate_user!

    # ── menu_id 系 ──

    # GET /api/goods/check?menu_id=123
    def check
      check_good(:menu_id)
    end

    # GET /api/goods/count?menu_id=1
    def count
      count_good(:menu_id)
    end

    # POST /api/goods
    def create
      id = params.dig(:good, :menu_id) || params[:menu_id]
      create_good(:menu_id, id)
    end

    # ── suggestion_id 系 ──

    # GET /api/goods/check_suggestion?suggestion_id=456
    def check_suggestion
      check_good(:suggestion_id)
    end

    # GET /api/goods/count_suggestion?suggestion_id=1
    def count_suggestion
      count_good(:suggestion_id)
    end

    # POST /api/goods/create_suggestion
    def create_suggestion
      id = params.dig(:good, :suggestion_id) || params[:suggestion_id]
      create_good(:suggestion_id, id)
    end

    # ── 共通 ──

    # DELETE /api/goods/:id
    # DELETE /api/goods/destroy_suggestion/:id
    def destroy
      good = current_user_good(params[:id])
      return render json: { error: "権限がありません" }, status: :unauthorized unless good

      good.destroy
      head :no_content
    end

    alias destroy_suggestion destroy

    private

    def check_good(key)
      value = params[key]
      return render json: { error: "#{key} が必要です" }, status: :bad_request if value.blank?

      good = Good.find_by(user_id: @current_user.id, key => value)
      render json: { exists: good.present?, good: good ? { id: good.id } : nil }, status: :ok
    end

    def count_good(key)
      value = params[key]
      return render json: { error: "#{key} が必要です" }, status: :bad_request if value.blank?

      count = Good.where(key => value).count
      render json: { key => value.to_i, count: count }, status: :ok
    end

    def create_good(key, value)
      return render json: { error: "#{key} が必要です" }, status: :bad_request if value.blank?

      good = Good.find_by(user_id: @current_user.id, key => value)
      return render json: { id: good.id }, status: :ok if good

      good = Good.create!(user_id: @current_user.id, key => value)
      render json: { id: good.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    def current_user_good(id)
      Good.find_by(id: id, user_id: @current_user.id)
    end
  end
end