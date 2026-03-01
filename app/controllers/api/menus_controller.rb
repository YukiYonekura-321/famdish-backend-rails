module Api
  class MenusController < ApplicationController
    before_action :authenticate_user!
    before_action :set_family, only: [:index, :show]
    before_action :set_own_menu, only: [:update, :destroy]

    # GET /api/menus
    def index
      return render json: [], status: :ok unless @family

      menus = family_menus.includes(:member)

      render json: menus.as_json(
        only: [:id, :name],
        include: { member: { only: [:id, :name] } }
      ), status: :ok
    end

    # POST /api/menus
    def create
      member = @current_user.member
      return render json: { error: "メンバーが見つかりません" }, status: :forbidden unless member

      menu = Menu.create!(menu_params.merge(member: member))
      render json: { id: menu.id }, status: :created
    end

    # PATCH /api/menus/:id
    def update
      @menu.update!(menu_params)
      head :no_content
    end

    # DELETE /api/menus/:id
    def destroy
      @menu.destroy
      head :no_content
    end

    private

    def set_family
      @family = @current_user.family
    end

    def set_own_menu
      @menu = Menu.joins(:member)
                  .where(members: { user_id: @current_user.id })
                  .find_by(id: params[:id])
      render json: { error: "メニューが見つかりません" }, status: :not_found unless @menu
    end

    def family_menus
      Menu.joins(:member).where(members: { family_id: @family.id })
    end

    def menu_params
      params.require(:menu).permit(:name)
    end
  end
end
