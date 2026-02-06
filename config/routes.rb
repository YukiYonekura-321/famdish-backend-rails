Rails.application.routes.draw do
  get "/api/health", to: proc { [200, {}, ["ok"]] }

  namespace :api do
    resources :menus, only: [ :index, :show, :create, :update, :destroy ]
    resources :members, only: [ :index, :show, :create, :update, :destroy ] do
      # GET /api/members/me
      get :me, on: :collection
    end
    resources :likes, only: [ :index ]
    resources :suggestions, only: [:create, :update] do
      member do
        post :feedback
      end
    end
  end
end
