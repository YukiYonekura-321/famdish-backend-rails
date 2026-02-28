module Api
  class StocksController < ApplicationController
    before_action :authenticate_user!
    before_action :set_family
    before_action :set_stock, only: [:update, :destroy]

    # GET /api/stocks
    def index
      stocks = @family.stocks.order(:name)
      render json: stocks.map { |s| stock_json(s) }, status: :ok
    end

    # POST /api/stocks
    def create
      stock = @family.stocks.create!(stock_params)
      render json: stock_json(stock), status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    # PATCH /api/stocks/:id
    def update
      @stock.update!(stock_params)
      render json: stock_json(@stock), status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end

    # DELETE /api/stocks/:id
    def destroy
      @stock.destroy
      head :no_content
    end

    private

    def set_family
      @family = @current_user.family
      render json: { error: "家族が見つかりません" }, status: :bad_request unless @family
    end

    def set_stock
      @stock = @family.stocks.find_by(id: params[:id])
      render json: { error: "在庫が見つかりません" }, status: :not_found unless @stock
    end

    def stock_json(stock)
      { id: stock.id, name: stock.name, quantity: stock.quantity.to_f, unit: stock.unit }
    end

    def stock_params
      params.require(:stock).permit(:name, :quantity, :unit)
    end
  end
end
