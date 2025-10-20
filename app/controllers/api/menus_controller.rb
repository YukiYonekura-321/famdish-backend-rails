module Api
  class MenusController < ApplicationController
    before_action :authenticate_user!

    def index
      menus = Menu.all
      render json: menus
    end

    def show
      menu = Menu.find(params[:id])
      render json: menu
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メニューが見つかりません")
    end

    def create
      menu = Menu.new(menu_params)
      if menu.save
        render json: menu, status: :created
      else
        render json: { errors: menu.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      menu = Menu.find(params[:id])
      if menu.update(menu_params)
        render json: menu, status: :ok
      else
        render json: { errors: menu.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メニューが見つかりません")
    end 

    def destroy
      menu = Menu.find(params[:id])
      menu.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メニューが見つかりません")
    end

    private

    def menu_params
      params.require(:menu).permit(:menu)
    end
  end
end
