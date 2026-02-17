module Api
  class StocksController < ApplicationController
    before_action :authenticate_user!

    # GET /api/stocks
    # 自分の家族の冷蔵庫在庫一覧
    def index
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      stocks = family.stocks.order(:name)
      render json: stocks.map { |s|
        { id: s.id, name: s.name, quantity: s.quantity.to_f, unit: s.unit }
      }, status: :ok
    end

    # POST /api/stocks
    # body: { stock: { name: "卵", quantity: 10, unit: "個" } }
    def create
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      stock = family.stocks.create!(stock_params)
      render json: { id: stock.id, name: stock.name, quantity: stock.quantity.to_f, unit: stock.unit }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    # PATCH /api/stocks/:id
    # body: { stock: { quantity: 5 } }
    def update
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      stock = family.stocks.find_by(id: params[:id])
      return render json: { error: "在庫が見つかりません" }, status: :not_found unless stock

      stock.update!(stock_params)
      render json: { id: stock.id, name: stock.name, quantity: stock.quantity.to_f, unit: stock.unit }, status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    # DELETE /api/stocks/:id
    def destroy
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      stock = family.stocks.find_by(id: params[:id])
      return render json: { error: "在庫が見つかりません" }, status: :not_found unless stock

      stock.destroy
      head :no_content
    end

    private

    def stock_params
      params.require(:stock).permit(:name, :quantity, :unit)
    end
  end
end
