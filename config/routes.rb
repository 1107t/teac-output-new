# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  # ===========================================================
  # API v1
  # ===========================================================
  namespace :api do
    namespace :v1 do
      # --- ユーザー認証 ---
      scope :auth do
        post   'signup',  to: 'auth/users#signup'
        post   'login',   to: 'auth/users#login'
        delete 'logout',  to: 'auth/users#logout'
        get    'me',      to: 'auth/users#me'
      end

      # --- 管理者認証 ---
      scope 'admin/auth' do
        post   'login',  to: 'auth/admins#login'
        delete 'logout', to: 'auth/admins#logout'
        get    'me',     to: 'auth/admins#me'
      end

      # --- マネージャー認証 ---
      scope 'manager/auth' do
        post   'login',  to: 'auth/managers#login'
        delete 'logout', to: 'auth/managers#logout'
        get    'me',     to: 'auth/managers#me'
      end

      # --- マネージャー向けリソース ---
      namespace :manager do
        resources :tenants, only: [:index, :show, :create]
      end

      # --- ユーザー向けリソース ---
      resources :posts, only: [:index, :show, :create, :update, :destroy], controller: 'users/posts' do
        post   'likes', to: 'users/likes#post_create',   as: :post_like
        delete 'likes', to: 'users/likes#post_destroy'
      end
      resources :articles, only: [:index, :show, :create, :update, :destroy], controller: 'users/articles' do
        post   'likes', to: 'users/likes#article_create', as: :article_like
        delete 'likes', to: 'users/likes#article_destroy'
      end
      resources :tweets, only: [:index, :show, :create, :update, :destroy], controller: 'users/tweets' do
        # いいね: POST /api/v1/tweets/:tweet_id/like, DELETE /api/v1/tweets/:tweet_id/like
        resource :like,     only: [:create, :destroy], controller: 'users/tweet_likes'
        # コメント: POST /api/v1/tweets/:tweet_id/comments
        resources :comments, only: [:create],          controller: 'users/tweet_comments'
      end
      resources :inquiries, only: [:index, :show, :create],                    controller: 'users/inquiries'
      resources :learnings, only: [:index, :create],                           controller: 'users/learnings'
      resources :stocks,    only: [:index, :create, :destroy],                 controller: 'users/stocks'
      resource  :profile,   only: [:show, :update],                            controller: 'users/profiles'

      # --- 管理者向けリソース ---
      namespace :admin do
        resources :users, only: [:index, :show, :update, :destroy] do
          # 管理者がユーザーのつぶやきを閲覧するエンドポイント: GET /api/v1/admin/users/:user_id/tweets
          # namespace :admin の内側にいるため controller: 'tweets' だけで Api::V1::Admin::TweetsController を指す
          resources :tweets, only: [:index], controller: 'tweets'
          # 管理者がユーザーの記事一覧を閲覧するエンドポイント: GET /api/v1/admin/users/:user_id/articles
          # controller を user_articles に指定して Api::V1::Admin::UserArticlesController を指す。
          # 既存のトップレベル Api::V1::Admin::ArticlesController（記事CRUD）とクラス名が衝突するため専用名にする
          resources :articles, only: [:index], controller: 'user_articles'
          # 管理者がユーザーの動画投稿一覧を閲覧するエンドポイント: GET /api/v1/admin/users/:user_id/posts
          # 同様に user_posts を指定して Api::V1::Admin::UserPostsController を指す
          resources :posts, only: [:index], controller: 'user_posts'
        end
        resources :articles,  only: [:index, :show, :create, :update, :destroy]
        resources :posts,     only: [:index, :show, :create, :update, :destroy]
        resources :learnings, only: [:index, :create]
      end
    end
  end
  # ===========================================================


  # admin関連=========================================================
  devise_for :admins, controllers: {
    sessions:      'admins/sessions',
    passwords:     'admins/passwords',
    confirmations: 'admins/confirmations',
    registrations: 'admins/registrations'
  }

  namespace :admins do
    resources :posts
    resources :dash_boards, only: [:index]
    resources :charge_plans do
      collection do
        post 'confirm'
        get 'back'
        get 'complete'
      end
    end
    resources :articles do
      member do
        get 'users_show'
        get 'users_edit'
        patch 'users_update'
        delete 'users_destroy'
      end
    end
    namespace :articles do
      post 'image'
    end
    resources :users do
      collection do
        get 'admins_show'
      end
    end
    resources :inquiries
    resources :learnings, only: [:index, :show, :create]
  end

  # =================================================================

  # user関連==========================================================
  devise_scope :user do
    root 'users/sessions#new'
  end

  devise_for :users, controllers: {
    sessions:      'users/sessions',
    passwords:     'users/passwords',
    confirmations: 'users/confirmations',
    registrations: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  namespace :users do
    resources :dash_boards, only: [:index]
    resources :chat_rooms, only: [:create, :show]
    resources :stocks, only:[:create, :destroy, :index]
    resources :learnings, only: [:index, :show, :create]
    resources :folders, only: [:create, :show, :update, :destroy]
    resources :checkouts, only: [:new, :create] do
      get 'complete', on: :collection
    end
    resources :subscriptions, only: [:new, :create] do
      get 'complete', on: :collection
    end
    resources :articles do
      resources :article_comments, only: %i[create destroy update] # 記事コメント機能
      resource :likes, only: [] do
        post 'article_create', on: :member
        delete 'article_destroy', on: :member
      end
      post 'assign_folder/:folder_id', to: 'article_folders#assign_folder', as: 'assign_folder'
    end
    resources :users do
      resource :posts, only: [] do
        get 'index_user', on: :member
      end
      resources :payments, only: [:index]
      resource :relationships, only: [:index, :create, :destroy]
        get :followings, :followers, on: :member
    end
    resources :users, only: [:show]
    resources :posts do
      resources :post_comments, only: %i[create destroy update]
      resource :likes, only: [] do
        post 'post_create', on: :member
        delete 'post_destroy', on: :member
      end
    end
    resources :articles
    namespace :articles do
      post 'image'
    end
    namespace :users do
      resources :users, only: [:index]
    end
    resources :profiles
    resources :tweets do # つぶやき機能
      member do
        get 'index_user'
      end
      resources :tweet_comments, only: %i[create destroy update] do # コメント機能
        member do # 個々のコメントに対してアクセスできるカスタムアクションを定義する
          patch 'confirmed_notification' # confirmed_notificationアクションに対するRESTfulなルーティングを定義
        end
      end
    end
    resources :inquiries
  end
  # =================================================================

  # manager関連=======================================================
  devise_for :managers, controllers: {
    sessions:      'managers/sessions',
    passwords:     'managers/passwords',
    confirmations: 'users/confirmations',
    registrations: 'managers/registrations'
  }

  namespace :managers do
    resources :tenants, only: [:index, :show, :new, :create, :destroy]
    resources :profiles do
      collection do
        get 'managers_show'
      end
    end
  end
  # =================================================================

  # 共通==============================================================
  # 利用規約
  get 'use' => 'use#index'
  # =================================================================
end
