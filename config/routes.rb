Rails.application.routes.draw do
  swagger_auth = lambda do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username.to_s, ENV.fetch('SWAGGER_USERNAME', '')) &
      ActiveSupport::SecurityUtils.secure_compare(password.to_s, ENV.fetch('SWAGGER_PASSWORD', ''))
  end

  mount Rack::Auth::Basic.new(Rswag::Ui::Engine, 'My Finance API Docs', &swagger_auth) => '/api-docs'
  mount Rack::Auth::Basic.new(Rswag::Api::Engine, 'My Finance API Docs', &swagger_auth) => '/api-docs'

  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :v1 do

    resources :users, only: [] do
      collection do
        get :me
      end
    end

    resources :wallets do
      collection do
        get :main
      end
    end

    resources :transactions

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
end
