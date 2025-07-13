module Api
  class MenusController < ApplicationController
    before_action :authenticate_user!

    def index
      render json: {
        date: "2025-07-09",
        items: [ "ごはん", "味噌汁", "焼き魚", "サラダ" ]
      }
      # menus = Menu.all
      # render json: menus
    end
  end
end
