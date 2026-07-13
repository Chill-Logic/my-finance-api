require 'rails_helper'
require 'request_helper'

RSpec.describe V1::CreditBalancesController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "retorna os saldos de crédito da carteira com usado/disponível" do
      make_request(endpoint: v1_credit_balances_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].map { |cb| cb["id"] }).to match_array([credit_balances(:gabriel_nubank).id])
      credit_balance = body["data"].first
      expect(credit_balance["credit_limit"]).to eq(1000000)
      expect(credit_balance).to have_key("used")
      expect(credit_balance).to have_key("available")
      expect(credit_balance["current_invoice"]).to have_key("due_date")
    end

    it "retorna erro se o usuário não tem acesso à carteira" do
      make_request(endpoint: v1_credit_balances_path, token: second_user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Carteira não encontrada.")
    end
  end

  describe "GET #show" do
    it "retorna um saldo de crédito acessível" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}", token: user_token, method: :get)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["id"]).to eq(credit_balances(:gabriel_nubank).id)
    end

    it "retorna erro para saldo de crédito sem acesso" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:shared_credit).id}", token: second_user_token, method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Saldo de crédito não encontrado.")
    end
  end

  describe "POST #create" do
    it "cria um saldo de crédito na carteira" do
      params = { wallet_id: wallets(:gabriel_main).id, credit_balance: { name: "Inter Gold", credit_limit: 300000, closing_day: 20, due_day: 27 } }
      make_request(endpoint: v1_credit_balances_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["name"]).to eq("Inter Gold")
      expect(body["data"]["wallet_id"]).to eq(wallets(:gabriel_main).id)
    end

    it "retorna erro se dados inválidos" do
      params = { wallet_id: wallets(:gabriel_main).id, credit_balance: { name: "", credit_limit: nil, closing_day: nil, due_day: nil } }
      make_request(endpoint: v1_credit_balances_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to be_present
    end
  end

  describe "PATCH #update" do
    it "atualiza um saldo de crédito acessível" do
      params = { credit_balance: { credit_limit: 1200000 } }
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}", token: user_token, method: :patch, params: params)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]["credit_limit"]).to eq(1200000)
    end
  end

  describe "DELETE #destroy" do
    it "remove um saldo de crédito acessível" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:shared_credit).id}", token: user_token, method: :delete)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Saldo de crédito removido com sucesso!")
      expect(CreditBalance.find_by(id: credit_balances(:shared_credit).id)).to be_nil
    end
  end

  describe "GET #invoice" do
    it "calcula a fatura do ciclo pela soma das compras" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { date: "2026-08-15" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]["amount"]).to eq(350000)
      expect(body["data"]["due_date"]).to eq("2026-09-10")
      expect(body["data"]["paid"]).to eq(false)
    end
  end

  describe "POST #pay_invoice" do
    it "paga a fatura criando um saque efetivado na conta pagadora" do
      expect {
        make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      }.to change { accounts(:gabriel_main_account).reload.balance }.by(-350000)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["value"]).to eq(350000)
      expect(body["data"]["kind"]).to eq("withdraw")
      expect(body["data"]["source_type"]).to eq("Account")
      expect(body["data"]["source_id"]).to eq(accounts(:gabriel_main_account).id)
      expect(body["data"]["paid_credit_balance_id"]).to eq(credit_balances(:gabriel_nubank).id)
      expect(body["data"]["settled"]).to eq(true)
    end

    it "marca a fatura como paga após o pagamento" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { date: "2026-08-15" })
      expect(JSON.parse(response.body)["data"]["paid"]).to eq(true)
    end

    it "recusa segundo pagamento da mesma fatura" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Fatura já foi paga.")
    end

    it "recusa quando a conta pagadora não é acessível" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:maria_main_account).id, date: "2026-08-15" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Conta pagadora não encontrada.")
    end

    it "recusa quando não há fatura em aberto no ciclo" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-01-15" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Não há fatura em aberto para pagar.")
    end
  end
end
