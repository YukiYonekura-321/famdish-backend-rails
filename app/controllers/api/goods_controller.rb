module Api
  class GoodsController < ApplicationController
    before_action :authenticate_user!

    # ── menu_id 系 ──

    # GET /api/goods/check?menu_id=123
    def check
      menu_id = params[:menu_id]
      return render json: { error: "menu_id が必要です" }, status: :bad_request unless menu_id.present?

      good = Good.find_by(user_id: @current_user.id, menu_id: menu_id)
      render json: {
        exists: good.present?,
        good: good ? { id: good.id } : nil
      }, status: :ok
    end

    # GET /api/goods/count?menu_id=1
    def count
      menu_id = params[:menu_id]
      return render json: { error: "menu_id が必要です" }, status: :bad_request unless menu_id.present?

      count = Good.where(menu_id: menu_id).count
      render json: { menu_id: menu_id.to_i, count: count }, status: :ok
    end

    # POST /api/goods
    # body: { good: { menu_id: 1 } }
    def create
      menu_id = params.dig(:good, :menu_id) || params[:menu_id]
      return render json: { error: "menu_id が必要です" }, status: :bad_request unless menu_id.present?

      good = Good.find_by(user_id: @current_user.id, menu_id: menu_id)
      return render json: { id: good.id }, status: :ok if good

      good = Good.create!(user_id: @current_user.id, menu_id: menu_id)
      render json: { id: good.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    # ── suggestion_id 系 ──

    # GET /api/goods/check_suggestion?suggestion_id=456
    def check_suggestion
      suggestion_id = params[:suggestion_id]
      return render json: { error: "suggestion_id が必要です" }, status: :bad_request unless suggestion_id.present?

      good = Good.find_by(user_id: @current_user.id, suggestion_id: suggestion_id)
      render json: {
        exists: good.present?,
        good: good ? { id: good.id } : nil
      }, status: :ok
    end

    # GET /api/goods/count_suggestion?suggestion_id=1
    def count_suggestion
      suggestion_id = params[:suggestion_id]
      return render json: { error: "suggestion_id が必要です" }, status: :bad_request unless suggestion_id.present?

      count = Good.where(suggestion_id: suggestion_id).count
      render json: { suggestion_id: suggestion_id.to_i, count: count }, status: :ok
    end

    # POST /api/goods/create_suggestion
    # body: { good: { suggestion_id: 1 } }
    def create_suggestion
      suggestion_id = params[:suggestion_id]
      Rails.logger.info "create_suggestion - suggestion_id: #{suggestion_id.inspect}, user_id: #{@current_user.id}"
      
      return render json: { error: "suggestion_id が必要です" }, status: :bad_request unless suggestion_id.present?

      good = Good.find_by(user_id: @current_user.id, suggestion_id: suggestion_id)
      return render json: { id: good.id }, status: :ok if good

      good = Good.create!(user_id: @current_user.id, suggestion_id: suggestion_id)
      render json: { id: good.id }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "create_suggestion validation error: #{e.record.errors.full_messages.inspect}"
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "create_suggestion error: #{e.class} - #{e.message}"
      raise
    end

    # ── 共通 ──

    # DELETE /api/goods/:id
    def destroy
      good = Good.find_by(id: params[:id], user_id: @current_user.id)
      return render json: { error: "権限がありません" }, status: :unauthorized unless good

      good.destroy
      head :no_content
    end

    # DELETE /api/goods/destroy_suggestion/:id
    def destroy_suggestion
      good = Good.find_by(id: params[:id], user_id: @current_user.id)
      return render json: { error: "権限がありません" }, status: :unauthorized unless good

      good.destroy
      head :no_content
    end
  end
end