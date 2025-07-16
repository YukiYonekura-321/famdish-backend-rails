module Api
  class MenusController < ApplicationController
    before_action :authenticate_user!

    def index
      menus = Menu.all
      render json: menus
    end
  end
end
