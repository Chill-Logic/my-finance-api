Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do

    resources :users, only: [] do
      collection do
        get :me
        match :me, to: 'users#update', via: [:patch, :put], as: :update_me
      end
    end

    resources :wallets do
      collection do
        get :main
      end
    end

    resources :accounts
    resources :credit_balances do
      member do
        get :invoice
        post :pay_invoice
      end
    end
    resources :credit_cards

    resources :transactions do
      member do
        post :settle
        post :unsettle
      end
    end

    resources :user_wallets, only: [:index, :create] do
      member do
        post :accept
        post :reject
      end
    end

    namespace :core do
      get 'version', to: 'version#show'

      resources :enums, only: [] do
        collection do
          get 'options/:entity/:type', to: 'enums#options'
        end
      end
    end

    resource :auth do
      post :sign_in
      post :sign_up
      post :recover_password
      post :reset_password
    end
  end

  match '*unmatched', to: 'application#route_not_found', via: :all
end
