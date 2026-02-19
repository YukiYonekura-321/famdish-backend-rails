Rails.application.routes.draw do
  get "/api/health", to: proc { [200, {}, ["ok"]] }

  namespace :api do
    resources :menus, only: [ :index, :show, :create, :update, :destroy ]
    resources :members, only: [ :index, :show, :create, :update, :destroy ] do
      # GET /api/members/me
      get :me, on: :collection
    end
    resources :likes, only: [ :index ]
    resources :stocks, only: [ :index, :create, :update, :destroy ]
    resources :suggestions, only: [:create, :update] do
      collection do
        get :check
        get :index
      end
      member do
        post :feedback
      end
    end

    # 担当者設定
    resources :families, only: [:index] do
      collection do
        post :assign_cook
      end
    end

    # Good（menu_id 系）
    get "goods/check", to: "goods#check"
    resources :goods, only: [:create, :destroy] do
      collection do
        get :count
      end
    end

    # Good（suggestion_id 系）
    get "goods/check_suggestion", to: "goods#check_suggestion"
    get "goods/count_suggestion", to: "goods#count_suggestion"
    post "goods/create_suggestion", to: "goods#create_suggestion"
    delete "goods/destroy_suggestion/:id", to: "goods#destroy_suggestion"

    # レシピ説明
    post "recipes/explain", to: "recipes#explain"

    # 招待機能
    resources :invitations, only: [:create], param: :token do
      member do
        post :accept  # POST /api/invitations/:token/accept
      end
    end
    # GET /api/invitations/:token（show は認証不要なので別途定義）
    get "invitations/:token", to: "invitations#show", as: :invitation_show
  end
end
