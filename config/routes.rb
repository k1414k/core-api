Rails.application.routes.draw do
  # 共通APIとして、サービス別の入り口を最上位に置き、
  # その下にバージョン（v1）をぶら下げる構造にする。
  #
  # /auction/... : オークション系フロント（auction.jongin.blog）向け
  # /admin/...   : 将来の管理画面（admin.jongin.blog）向けを想定
  # /web/...     : メインサイト（jongin.blog）向けを想定

  # 認証エンドポイントはサービス共通で /auth にまとめる。
  mount_devise_token_auth_for "User", at: "auth"
  
  namespace :admin do
    namespace :v1, module: :v1, path: "v1" do
      resources :users, only: [:index] do
        member do
          patch :role, action: :update_role
          patch :permissions, action: :update_permissions
        end
      end
      get "dashboard", to: "dashboard#index"
      resources :items
      resources :categories
    end
  end


  namespace :web do
    namespace :v1 do
      resources :posts, only: [:index], param: :slug
      get "posts/:slug", to: "posts#show"
    end
  end

  
  namespace :auction do
    namespace :v1, module: :v1, path: "v1" do
      get "user", to: "users#my_profile"
      get "user/items", to: "users#my_items"
      patch "user/wallet", to: "users#update_wallet"
      patch "user/avatar", to: "users#update_avatar"

      get "users/:id/items", to: "items#user_items"

      put "favorites/:item_id", to: "favorites#toggle"
      resources :categories, only: [:index]
      get "items/ending_soon", to: "items#ending_soon"
      get "items/one_yen", to: "items#one_yen"
      get "items/recently_sold", to: "items#recently_sold"
      resources :items do
        resources :bids, only: [:index, :create], controller: "bids"
        resources :offers, only: [:create], controller: "offers"
      end
      resources :offers, only: [:update], controller: "offers"
      resources :addresses, only: [:index, :create, :update, :destroy]
      resources :orders, only: [:index, :show, :create, :update], controller: "order" do
        resources :messages, only: [:index, :create], controller: "messages"
      end
    end
  end
end
