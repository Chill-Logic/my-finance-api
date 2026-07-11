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

  describe "PATCH #update" do
    it "atualiza nome e email do usuário autenticado" do
      make_request(
        endpoint: update_me_v1_users_path,
        token: user_token,
        method: :patch,
        params: { user: { name: "Gabriel Paranhos", email: "novo@example.com" } }
      )

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["name"]).to eq("Gabriel Paranhos")
      expect(body["data"]["email"]).to eq("novo@example.com")

      gabriel = users(:gabriel).reload
      expect(gabriel.name).to eq("Gabriel Paranhos")
      expect(gabriel.email).to eq("novo@example.com")
    end

    it "não exige senha atual para atualizar apenas o perfil" do
      make_request(
        endpoint: update_me_v1_users_path,
        token: user_token,
        method: :patch,
        params: { user: { name: "Só o nome" } }
      )

      expect(response).to have_http_status(:ok)
      expect(users(:gabriel).reload.name).to eq("Só o nome")
    end

    it "altera a senha quando a senha atual está correta" do
      make_request(
        endpoint: update_me_v1_users_path,
        token: user_token,
        method: :patch,
        params: { user: { current_password: "123123", password: "novasenha", password_confirmation: "novasenha" } }
      )

      expect(response).to have_http_status(:ok)
      expect(users(:gabriel).reload.valid_password?("novasenha")).to be(true)
    end

    it "bloqueia a alteração de senha com a senha atual incorreta" do
      make_request(
        endpoint: update_me_v1_users_path,
        token: user_token,
        method: :patch,
        params: { user: { current_password: "errada", password: "novasenha", password_confirmation: "novasenha" } }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Senha atual incorreta.")
      expect(users(:gabriel).reload.valid_password?("123123")).to be(true)
    end

    it "retorna erro quando a confirmação de senha não confere" do
      make_request(
        endpoint: update_me_v1_users_path,
        token: user_token,
        method: :patch,
        params: { user: { current_password: "123123", password: "novasenha", password_confirmation: "diferente" } }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(users(:gabriel).reload.valid_password?("123123")).to be(true)
    end

    it "retorna erro de validação para nome em branco" do
      make_request(
        endpoint: update_me_v1_users_path,
        token: user_token,
        method: :patch,
        params: { user: { name: "" } }
      )

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "retorna erro de validação para email já em uso" do
      make_request(
        endpoint: update_me_v1_users_path,
        token: user_token,
        method: :patch,
        params: { user: { email: users(:maria).email } }
      )

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "bloqueia a requisição sem token" do
      make_request(endpoint: update_me_v1_users_path, method: :patch, params: { user: { name: "Hacker" } })
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
