require 'rails_helper'
require 'request_helper'

RSpec.describe V1::AccountsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "retorna as contas da carteira paginadas com o saldo" do
      make_request(endpoint: v1_accounts_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |account| account["id"] }).to match_array([accounts(:gabriel_main_account).id])
      expect(body["data"].first["balance"]).to eq(475000)
      expect(body["data"].first["translated_kind"]).to eq("Dinheiro")
      expect(body).to have_key("total_count")
      expect(body).to have_key("total_pages")
    end

    it "retorna erro se o usuário não tem acesso à carteira" do
      make_request(endpoint: v1_accounts_path, token: second_user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end
  end

  describe "GET #show" do
    it "retorna uma conta acessível" do
      make_request(endpoint: v1_accounts_path + "/#{accounts(:gabriel_main_account).id}", token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(accounts(:gabriel_main_account).id)
    end

    it "retorna erro para conta sem acesso" do
      make_request(endpoint: v1_accounts_path + "/#{accounts(:maria_main_account).id}", token: user_token, method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Conta não encontrada.")
    end
  end

  describe "POST #create" do
    it "cria uma conta na carteira" do
      params = { wallet_id: wallets(:gabriel_main).id, account: { name: "Inter", kind: "checking", initial_balance: 10000 } }
      make_request(endpoint: v1_accounts_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["name"]).to eq("Inter")
      expect(body["data"]["wallet_id"]).to eq(wallets(:gabriel_main).id)
      expect(body["data"]["balance"]).to eq(10000)
    end

    it "retorna erro se dados inválidos" do
      params = { wallet_id: wallets(:gabriel_main).id, account: { name: "" } }
      make_request(endpoint: v1_accounts_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end
  end

  describe "PATCH #update" do
    it "atualiza uma conta acessível" do
      params = { account: { name: "Carteira física" } }
      make_request(endpoint: v1_accounts_path + "/#{accounts(:gabriel_main_account).id}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["name"]).to eq("Carteira física")
    end
  end

  describe "DELETE #destroy" do
    it "remove uma conta acessível" do
      make_request(endpoint: v1_accounts_path + "/#{accounts(:shared_account).id}", token: user_token, method: :delete)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Conta removida com sucesso!")
      expect(Account.find_by(id: accounts(:shared_account).id)).to be_nil
    end

    it "retorna erro se conta não existe" do
      make_request(endpoint: v1_accounts_path + "/#{RequestHelper::MISSING_UUID}", token: user_token, method: :delete)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Conta não encontrada.")
    end
  end
end
