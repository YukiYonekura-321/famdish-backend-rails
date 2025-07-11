Rails.application.routes.draw do
  namespace :api do
    resources :menus, only: [ :index ]
  end
end
