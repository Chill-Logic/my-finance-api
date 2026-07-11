require 'rails_helper'
require 'request_helper'

RSpec.describe V1::TransactionsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "retorna as transações da carteira paginadas com o saldo" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(3)
      expect(body["data"].first["id"]).to eq(transactions(:market).id)
      expect(body["total"]).to eq(475000)
      expect(body).to have_key("total_count")
      expect(body).to have_key("total_pages")
    end

    it "filtra as transações por período" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, start_date: "2026-07-01", end_date: "2026-07-31" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:salary).id, transactions(:market).id])
      expect(body["total"]).to eq(465000)
    end

    it "filtra por período usando o timezone opcional" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, start_date: "2026-07-01", end_date: "2026-07-31", timezone: "America/New_York" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:market).id])
    end

    it "usa o fuso da aplicação quando o timezone é inválido" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, start_date: "2026-07-01", end_date: "2026-07-31", timezone: "Fuso/Inexistente" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:salary).id, transactions(:market).id])
    end

    it "ignora datas não parseáveis em vez de zerar o resultado" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, start_date: "null", end_date: "undefined" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(3)
      expect(body["total"]).to eq(475000)
    end

    it "retorna erro se o usuário não tem acesso à carteira" do
      make_request(endpoint: v1_transactions_path, token: second_user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end

    it "retorna erro se a carteira não for enviada" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end
  end

  describe "GET #show" do
    it "retorna uma transação de carteira acessível" do
      make_request(endpoint: v1_transactions_path + "/#{transactions(:salary).id}", token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["id"]).to eq(transactions(:salary).id)
      expect(body["data"]["translated_kind"]).to eq("Depósito")
      expect(body["data"]["user_name"]).to eq("Gabriel")
    end

    it "retorna erro para transação de carteira sem acesso" do
      make_request(endpoint: v1_transactions_path + "/#{transactions(:salary).id}", token: second_user_token, method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Transação não encontrada.")
    end
  end

  describe "POST #create" do
    it "cria uma transação válida" do
      params = { transaction: { description: "Aluguel", value: 150000, kind: "withdraw", transaction_date: "2026-07-06", wallet_id: wallets(:gabriel_main).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["description"]).to eq("Aluguel")
      expect(body["data"]["wallet_id"]).to eq(wallets(:gabriel_main).id)
      expect(body["data"]["user_id"]).to eq(users(:gabriel).id)
    end

    it "retorna erro se dados inválidos" do
      params = { transaction: { description: "", value: nil, kind: nil, transaction_date: nil, wallet_id: wallets(:gabriel_main).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end

    it "retorna erro se o usuário não tem acesso à carteira" do
      params = { transaction: { description: "Aluguel", value: 150000, kind: "withdraw", transaction_date: "2026-07-06", wallet_id: wallets(:maria_main).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end
  end

  describe "PATCH #update" do
    it "atualiza uma transação existente" do
      params = { transaction: { description: "Feira" } }
      make_request(endpoint: v1_transactions_path + "/#{transactions(:market).id}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["description"]).to eq("Feira")
    end

    it "retorna erro se transação não existe" do
      params = { transaction: { description: "Feira" } }
      make_request(endpoint: v1_transactions_path + "/#{RequestHelper::MISSING_UUID}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Transação não encontrada.")
    end

    it "retorna erro se dados inválidos" do
      params = { transaction: { description: "" } }
      make_request(endpoint: v1_transactions_path + "/#{transactions(:market).id}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end
  end

  describe "DELETE #destroy" do
    it "remove uma transação existente" do
      make_request(endpoint: v1_transactions_path + "/#{transactions(:market).id}", token: user_token, method: :delete)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Transação removida com sucesso!")
      expect(Transaction.find_by(id: transactions(:market).id)).to be_nil
    end

    it "retorna erro se transação não existe" do
      make_request(endpoint: v1_transactions_path + "/#{RequestHelper::MISSING_UUID}", token: user_token, method: :delete)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Transação não encontrada.")
    end
  end
end
