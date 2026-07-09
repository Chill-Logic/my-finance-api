require 'rails_helper'
require 'request_helper'

RSpec.describe V1::WalletsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "retorna as carteiras acessíveis paginadas com o saldo" do
      make_request(endpoint: v1_wallets_path, token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |wallet| wallet["id"] }).to match_array([wallets(:gabriel_main).id, wallets(:shared).id, wallets(:casa).id])
      expect(body["data"].find { |wallet| wallet["id"] == wallets(:gabriel_main).id }["total"]).to eq(475000)
      expect(body).to have_key("total_count")
      expect(body).to have_key("total_pages")
    end

    it "não retorna carteiras com convite pendente" do
      make_request(endpoint: v1_wallets_path, token: second_user_token, method: :get)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |wallet| wallet["id"] }).to match_array([wallets(:maria_main).id, wallets(:casa).id])
    end
  end

  describe "GET #main" do
    it "retorna a carteira principal do usuário" do
      make_request(endpoint: main_v1_wallets_path, token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(wallets(:gabriel_main).id)
    end
  end

  describe "GET #show" do
    it "retorna uma carteira acessível" do
      make_request(endpoint: v1_wallets_path + "/#{wallets(:shared).id}", token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(wallets(:shared).id)
    end

    it "retorna erro para carteira sem acesso" do
      make_request(endpoint: v1_wallets_path + "/#{wallets(:maria_main).id}", token: user_token, method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end
  end

  describe "POST #create" do
    it "cria uma carteira com o vínculo do dono já aceito" do
      params = { wallet: { name: "Nova Carteira" } }
      make_request(endpoint: v1_wallets_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["name"]).to eq("Nova Carteira")
      expect(body["data"]["owner_id"]).to eq(users(:gabriel).id)

      wallet = Wallet.find(body["data"]["id"])
      expect(wallet.user_wallets.accepted.where(user_id: users(:gabriel).id)).to be_present
    end

    it "retorna erro se dados inválidos" do
      params = { wallet: { name: "" } }
      make_request(endpoint: v1_wallets_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end
  end

  describe "PATCH #update" do
    it "atualiza a carteira do dono" do
      params = { wallet: { name: "Novo Nome" } }
      make_request(endpoint: v1_wallets_path + "/#{wallets(:gabriel_main).id}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["name"]).to eq("Novo Nome")
    end

    it "bloqueia a atualização por quem não é dono" do
      params = { wallet: { name: "Novo Nome" } }
      make_request(endpoint: v1_wallets_path + "/#{wallets(:casa).id}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["message"]).to eq("Apenas o dono da carteira pode realizar essa ação.")
    end

    it "retorna erro se carteira não existe" do
      params = { wallet: { name: "Novo Nome" } }
      make_request(endpoint: v1_wallets_path + "/#{RequestHelper::MISSING_UUID}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end
  end

  describe "DELETE #destroy" do
    it "remove a carteira do dono" do
      make_request(endpoint: v1_wallets_path + "/#{wallets(:shared).id}", token: user_token, method: :delete)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira removida com sucesso!")
      expect(Wallet.find_by(id: wallets(:shared).id)).to be_nil
      expect(UserWallet.find_by(id: user_wallets(:gabriel_shared).id)).to be_nil
    end

    it "bloqueia a remoção por quem não é dono" do
      make_request(endpoint: v1_wallets_path + "/#{wallets(:casa).id}", token: user_token, method: :delete)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
