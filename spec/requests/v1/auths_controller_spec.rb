require 'rails_helper'
require 'request_helper'

RSpec.describe V1::AuthsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "POST #sign_in" do
    it "bloqueia o login do usuário caso o email não exista" do
      make_request(endpoint: v1_auth_path + "/sign_in", method: :post, params: { email: "test@example.com", password: "123123" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("E-mail ou senha inválidos.")
    end

    it "bloqueia o login do usuário caso a senha esteja incorreta" do
      make_request(endpoint: v1_auth_path + "/sign_in", method: :post, params: { email: "gabriel@example.com", password: "12" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("E-mail ou senha inválidos.")
    end

    it "bloqueia o login do usuário caso o email não seja enviado" do
      make_request(endpoint: v1_auth_path + "/sign_in", method: :post, params: { password: "123123" })
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "faz o login do usuário" do
      make_request(endpoint: v1_auth_path + "/sign_in", method: :post, params: { email: "gabriel@example.com", password: "123123" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["email"]).to eq("gabriel@example.com")
      expect(body["data"]["name"]).to eq("Gabriel")
      expect(body["data"]["token"]).to be_present
    end
  end

  describe "POST #sign_up" do
    it "cria o usuário com a carteira padrão" do
      params = { name: "Novo Usuário", email: "novo@example.com", password: "123123" }
      make_request(endpoint: v1_auth_path + "/sign_up", method: :post, params: params)
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["message"]).to eq("Usuário criado com sucesso!")

      user = User.find_by(email: "novo@example.com")
      expect(user).to be_present
      expect(user.main_user_wallet).to be_present
      expect(user.main_user_wallet.accepted).to be(true)
      expect(user.main_user_wallet.wallet.name).to eq("Minha Carteira")
      expect(user.main_user_wallet.wallet.owner_id).to eq(user.id)
    end

    it "bloqueia a criação caso o email já esteja em uso" do
      params = { name: "Repetido", email: "gabriel@example.com", password: "123123" }
      make_request(endpoint: v1_auth_path + "/sign_up", method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end

    it "bloqueia a criação caso os dados sejam inválidos" do
      make_request(endpoint: v1_auth_path + "/sign_up", method: :post, params: { name: "", email: "", password: "" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end
  end
end
