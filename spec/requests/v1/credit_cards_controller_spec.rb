require 'rails_helper'
require 'request_helper'

RSpec.describe V1::CreditCardsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "retorna os cartões do saldo de crédito paginados" do
      make_request(endpoint: v1_credit_cards_path, token: user_token, method: :get, params: { credit_balance_id: credit_balances(:gabriel_nubank).id })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |card| card["id"] }).to match_array([credit_cards(:gabriel_nubank_fisico).id, credit_cards(:gabriel_nubank_virtual).id])
      expect(body).to have_key("total_count")
      expect(body).to have_key("total_pages")
    end

    it "retorna erro se o usuário não tem acesso ao saldo de crédito" do
      make_request(endpoint: v1_credit_cards_path, token: second_user_token, method: :get, params: { credit_balance_id: credit_balances(:gabriel_nubank).id })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Saldo de crédito não encontrado.")
    end
  end

  describe "GET #show" do
    it "retorna um cartão acessível" do
      make_request(endpoint: v1_credit_cards_path + "/#{credit_cards(:gabriel_nubank_fisico).id}", token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(credit_cards(:gabriel_nubank_fisico).id)
    end

    it "retorna erro para cartão sem acesso" do
      make_request(endpoint: v1_credit_cards_path + "/#{credit_cards(:gabriel_nubank_fisico).id}", token: second_user_token, method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Cartão não encontrado.")
    end
  end

  describe "POST #create" do
    it "cria um cartão no saldo de crédito" do
      params = { credit_balance_id: credit_balances(:gabriel_nubank).id, credit_card: { name: "Adicional", last_digits: "9999" } }
      make_request(endpoint: v1_credit_cards_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["name"]).to eq("Adicional")
      expect(body["data"]["credit_balance_id"]).to eq(credit_balances(:gabriel_nubank).id)
    end

    it "retorna erro se dados inválidos" do
      params = { credit_balance_id: credit_balances(:gabriel_nubank).id, credit_card: { name: "" } }
      make_request(endpoint: v1_credit_cards_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end
  end

  describe "PATCH #update" do
    it "atualiza um cartão acessível" do
      params = { credit_card: { name: "Físico Renomeado" } }
      make_request(endpoint: v1_credit_cards_path + "/#{credit_cards(:gabriel_nubank_fisico).id}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["name"]).to eq("Físico Renomeado")
    end
  end

  describe "DELETE #destroy" do
    it "remove um cartão acessível" do
      make_request(endpoint: v1_credit_cards_path + "/#{credit_cards(:gabriel_nubank_virtual).id}", token: user_token, method: :delete)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Cartão removido com sucesso!")
      expect(CreditCard.find_by(id: credit_cards(:gabriel_nubank_virtual).id)).to be_nil
    end

    it "retorna erro se cartão não existe" do
      make_request(endpoint: v1_credit_cards_path + "/#{RequestHelper::MISSING_UUID}", token: user_token, method: :delete)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Cartão não encontrado.")
    end
  end
end
