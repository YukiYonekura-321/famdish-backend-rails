module Api
  class LikesController < ApplicationController
    before_action :authenticate_user!

    def index
      likes = Like.all
      render json: likes
    end
  end
end