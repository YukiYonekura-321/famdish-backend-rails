Rails.application.routes.draw do
  get "/api/health", to: proc { [200, {}, ["ok"]] }

  namespace :api do
    # メニュー
    resources :menus, only: [:index, :show, :create, :update, :destroy]

    # メンバー
    resources :members, only: [:index, :show, :create, :update, :destroy] do
      collection do
        get :me
        get :all
      end
    end

    # 好き嫌い
    resources :likes, only: [:index]

    # 在庫
    resources :stocks, only: [:index, :create, :update, :destroy]

    # 献立提案
    resources :suggestions, only: [:create, :update] do
      collection do
        get :check
        get :index
      end
      member do
        post :feedback
      end
    end

    # 家族・担当者設定
    resources :families, only: [:index] do
      collection do
        post :assign_cook
      end
    end

    # Good
    resources :goods, only: [:create, :destroy] do
      collection do
        get :check
        get :count
        get :check_suggestion
        get :count_suggestion
        post :create_suggestion
      end
      member do
        delete :destroy_suggestion
      end
    end

    # レシピ
    resources :recipes, only: [:index, :show, :create, :update, :destroy] do
      collection do
        get  :family_recipes
        post :explain
      end
    end

    # 招待
    resources :invitations, only: [:create], param: :token do
      member do
        post :accept
      end
    end
    get "invitations/:token", to: "invitations#show", as: :invitation_show
  end
end
