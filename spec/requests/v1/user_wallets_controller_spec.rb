require 'rails_helper'
require 'request_helper'

RSpec.describe V1::UserWalletsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "retorna os convites pendentes do usuário" do
      make_request(endpoint: v1_user_wallets_path, token: second_user_token, method: :get)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(1)
      expect(body["data"].first["id"]).to eq(user_wallets(:maria_shared_invite).id)
      expect(body["data"].first["wallet_name"]).to eq("Carteira Compartilhada")
      expect(body["data"].first["owner_name"]).to eq("Gabriel")
    end

    it "retorna array vazia quando não há convites pendentes" do
      make_request(endpoint: v1_user_wallets_path, token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).to eq([])
    end
  end

  describe "POST #create" do
    it "convida um usuário para a carteira" do
      params = { user_wallet: { user_email: "maria@example.com", wallet_id: wallets(:gabriel_main).id } }
      make_request(endpoint: v1_user_wallets_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["message"]).to eq("Usuário convidado com sucesso!")
      expect(UserWallet.pending.find_by(user_id: users(:maria).id, wallet_id: wallets(:gabriel_main).id)).to be_present
    end

    it "retorna erro se o email não existe" do
      params = { user_wallet: { user_email: "naoexiste@example.com", wallet_id: wallets(:gabriel_main).id } }
      make_request(endpoint: v1_user_wallets_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to eq("Não foi encontrado usuário com esse e-mail.")
    end

    it "retorna erro se o usuário não é dono da carteira" do
      params = { user_wallet: { user_email: "maria@example.com", wallet_id: wallets(:casa).id } }
      make_request(endpoint: v1_user_wallets_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end

    it "retorna erro se o usuário já foi convidado" do
      params = { user_wallet: { user_email: "maria@example.com", wallet_id: wallets(:shared).id } }
      make_request(endpoint: v1_user_wallets_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to include("já foi convidado para essa carteira")
    end
  end

  describe "POST #accept" do
    it "aceita um convite pendente" do
      make_request(endpoint: v1_user_wallets_path + "/#{user_wallets(:maria_shared_invite).id}/accept", token: second_user_token, method: :post)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Convite aceito com sucesso!")
      expect(user_wallets(:maria_shared_invite).reload.accepted).to be(true)
    end

    it "retorna erro se o convite não é do usuário" do
      make_request(endpoint: v1_user_wallets_path + "/#{user_wallets(:maria_shared_invite).id}/accept", token: user_token, method: :post)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to eq("Convite não encontrado ou já respondido.")
    end

    it "retorna erro se o convite já foi aceito" do
      make_request(endpoint: v1_user_wallets_path + "/#{user_wallets(:maria_main).id}/accept", token: second_user_token, method: :post)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to eq("Convite não encontrado ou já respondido.")
    end
  end

  describe "POST #reject" do
    it "recusa um convite pendente" do
      make_request(endpoint: v1_user_wallets_path + "/#{user_wallets(:maria_shared_invite).id}/reject", token: second_user_token, method: :post)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Convite recusado com sucesso!")
      expect(UserWallet.find_by(id: user_wallets(:maria_shared_invite).id)).to be_nil
    end

    it "retorna erro se o convite não existe" do
      make_request(endpoint: v1_user_wallets_path + "/#{RequestHelper::MISSING_UUID}/reject", token: second_user_token, method: :post)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["message"]).to eq("Convite não encontrado ou já respondido.")
    end
  end
end
