require 'rails_helper'
require 'request_helper'

RSpec.describe V1::TransactionsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "retorna as transações do mês com os totais efetivado e previsto" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 7, year: 2026 })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:salary).id, transactions(:market).id, transactions(:pending_bill).id, transactions(:draft_plan).id])
      # 500000 (salário) - 35000 (mercado); pendente e rascunho fora do efetivado
      expect(body["total_settled"]).to eq(465000)
      # inclui a pendente (-20000); rascunho continua fora
      expect(body["total_projected"]).to eq(445000)
      expect(body).to have_key("total_count")
      expect(body).to have_key("total_pages")
    end

    it "aceita o parâmetro reference no formato YYYY-MM" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, reference: "2026-06" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:old_deposit).id])
      expect(body["total_settled"]).to eq(10000)
      expect(body["total_projected"]).to eq(10000)
    end

    it "filtra por origem quando source_type/source_id são enviados" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 7, year: 2026, source_type: "Account", source_id: accounts(:gabriel_main_account).id })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(4)
      expect(body["total_settled"]).to eq(465000)
    end

    it "retorna erro se o usuário não tem acesso à carteira" do
      make_request(endpoint: v1_transactions_path, token: second_user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 7, year: 2026 })
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
    it "cria uma transação numa conta e sincroniza a carteira pela origem" do
      params = { transaction: { description: "Aluguel", value: 150000, kind: "withdraw", transaction_date: "2026-07-06", source_type: "Account", source_id: accounts(:gabriel_main_account).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["description"]).to eq("Aluguel")
      expect(body["data"]["source_type"]).to eq("Account")
      expect(body["data"]["source_id"]).to eq(accounts(:gabriel_main_account).id)
      expect(body["data"]["wallet_id"]).to eq(wallets(:gabriel_main).id)
      expect(body["data"]["user_id"]).to eq(users(:gabriel).id)
    end

    it "cria uma transação num saldo de crédito apontando o cartão" do
      params = { transaction: { description: "iFood", value: 8000, kind: "withdraw", transaction_date: "2026-07-06", source_type: "CreditBalance", source_id: credit_balances(:gabriel_nubank).id, credit_card_id: credit_cards(:gabriel_nubank_fisico).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["source_type"]).to eq("CreditBalance")
      expect(body["data"]["credit_card_id"]).to eq(credit_cards(:gabriel_nubank_fisico).id)
      expect(body["data"]["wallet_id"]).to eq(wallets(:gabriel_main).id)
    end

    it "rejeita cartão que não pertence ao saldo de crédito da origem" do
      params = { transaction: { description: "Compra", value: 8000, kind: "withdraw", transaction_date: "2026-07-06", source_type: "Account", source_id: accounts(:gabriel_main_account).id, credit_card_id: credit_cards(:gabriel_nubank_fisico).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end

    it "retorna erro se dados inválidos" do
      params = { transaction: { description: "", value: nil, kind: nil, transaction_date: nil, source_type: "Account", source_id: accounts(:gabriel_main_account).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end

    it "retorna erro se o usuário não tem acesso à origem" do
      params = { transaction: { description: "Aluguel", value: 150000, kind: "withdraw", transaction_date: "2026-07-06", source_type: "Account", source_id: accounts(:maria_main_account).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Origem não encontrada.")
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

  describe "POST #settle" do
    it "efetiva uma transação pendente" do
      make_request(endpoint: v1_transactions_path + "/#{transactions(:pending_bill).id}/settle", token: user_token, method: :post)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["settled"]).to eq(true)
      expect(body["data"]["settled_at"]).to be_present
      expect(transactions(:pending_bill).reload.settled_at).to be_present
    end

    it "aceita uma data de efetivação específica" do
      make_request(endpoint: v1_transactions_path + "/#{transactions(:pending_bill).id}/settle", token: user_token, method: :post, params: { settled_at: "2026-07-25T10:00:00" })
      expect(response).to have_http_status(:ok)
      expect(transactions(:pending_bill).reload.settled_at).to be_present
    end

    it "retorna erro se a transação não existe" do
      make_request(endpoint: v1_transactions_path + "/#{RequestHelper::MISSING_UUID}/settle", token: user_token, method: :post)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Transação não encontrada.")
    end
  end

  describe "POST #unsettle" do
    it "desfaz a efetivação de uma transação" do
      make_request(endpoint: v1_transactions_path + "/#{transactions(:salary).id}/unsettle", token: user_token, method: :post)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["settled"]).to eq(false)
      expect(transactions(:salary).reload.settled_at).to be_nil
    end
  end
end
