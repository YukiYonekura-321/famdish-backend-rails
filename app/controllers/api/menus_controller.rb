module Api
  class MenusController < ApplicationController
    before_action :authenticate_user!

    def index
      family = @current_user.family
      return render json: [], status: :ok unless family

      # family に属するメンバーが投稿したメニューのみ取得
      menus = Menu.joins(:member).where(members: { family_id: family.id }).includes(:member)

      render json: menus, status: :ok
    end

    def show
      family = @current_user.family
      return render_unauthorized("メニューが見つかりません") unless family

      menu = Menu.joins(:member)
             .where(members: { family_id: family.id })
             .includes(:member)
             .find_by(id: params[:id])
      return render_unauthorized("権限がありません") unless menu

      render json: menu, status: :ok
    end

    def create
      member = @current_user.member
      return render json: { error: "Member が見つかりません" }, status: :forbidden unless member

      menu = Menu.create!(menu_params.merge(member: member))
      render json: menu, status: :created
    end

    def update
      menu = Menu.joins(:member).where(members: { user_id: @current_user.id }).find_by(id: params[:id]).find(params[:id])
      
      return render_unauthorized("権限がありません") unless menu

      if menu.update(menu_params)
        render json: menu, status: :ok
      else
        render json: { errors: menu.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メニューが見つかりません")
    end 

    def destroy
      menu = Menu.joins(:member).where(members: { user_id: @current_user.id }).find_by(id: params[:id]).find(params[:id])
      menu.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メニューが見つかりません")
    end

    private

    def menu_params
      params.require(:menu).permit(:name)
    end
  end
end
