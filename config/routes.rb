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

    # Good テーブル確認
    get "goods/check", to: "goods#check"

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
