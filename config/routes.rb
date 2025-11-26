Rails.application.routes.draw do
  namespace :api do
    resources :menus, only: [ :index, :show, :create, :update, :destroy ]
    resources :members, only: [ :index, :show, :create, :update, :destroy ]
    resources :likes, only: [ :index ]
    resources :suggestions, only: [:create]
  end
end
