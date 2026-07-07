require 'rails_helper'
require 'request_helper'

RSpec.describe V1::UsersController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #me" do
    it "retorna o usuário autenticado" do
      make_request(endpoint: me_v1_users_path, token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["id"]).to eq(users(:gabriel).id)
      expect(body["data"]["email"]).to eq("gabriel@example.com")
      expect(body["data"]["main_user_wallet_id"]).to eq(user_wallets(:gabriel_main).id)
      expect(body["data"]).not_to have_key("encrypted_password")
    end

    it "bloqueia a requisição sem token" do
      make_request(endpoint: me_v1_users_path, method: :get)
      expect(response).to have_http_status(:unauthorized)
    end

    it "bloqueia a requisição com token expirado" do
      make_request(endpoint: me_v1_users_path, token: expired_token, method: :get)
      expect(response).to have_http_status(:unauthorized)
    end

    it "bloqueia a requisição com token inválido" do
      make_request(endpoint: me_v1_users_path, token: invalid_token, method: :get)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
