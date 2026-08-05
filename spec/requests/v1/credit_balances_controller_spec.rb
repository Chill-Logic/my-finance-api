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

    it "used soma todas as compras não-rascunho em aberto, incluindo ciclos anteriores e futuras" do
      # Nubank: pré-fechamento 12000 (jul) + notebook 300000 + curso 50000 (ago) + parcela futura 100000 (dez) = 462000.
      make_request(endpoint: v1_credit_balances_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      credit_balance = JSON.parse(response.body)["data"].first
      expect(credit_balance["used"]).to eq(462000)
      expect(credit_balance["available"]).to eq(1000000 - 462000)
    end

    it "pagamento efetivado libera limite de volta no used" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, reference: "2026-08" })
      expect(response).to have_http_status(:created)

      make_request(endpoint: v1_credit_balances_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id })
      credit_balance = JSON.parse(response.body)["data"].first
      # fatura de julho (12000) quitada → sobra 450000 em aberto
      expect(credit_balance["used"]).to eq(450000)
      expect(credit_balance["available"]).to eq(1000000 - 450000)
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

    it "current_invoice retorna a fatura em aberto com vencimento mais antigo" do
      # Em out/2026 o Nubank tem duas faturas em aberto: a de julho (vence 10/08, 12000) e a de
      # agosto (vence 10/09, 350000). A mais antiga não paga é a de 10/08.
      travel_to(Time.zone.local(2026, 10, 15)) do
        make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}", token: user_token, method: :get)
        invoice = JSON.parse(response.body)["data"]["current_invoice"]
        expect(invoice["amount"]).to eq(12000)
        expect(invoice["due_date"]).to eq("2026-08-10")
      end
    end

    it "avança para a próxima fatura em aberto quando a mais antiga é paga" do
      travel_to(Time.zone.local(2026, 10, 15)) do
        # paga a fatura mais antiga (faturada em ago → ciclo de julho, vence 10/08)
        make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, reference: "2026-08" })
        expect(response).to have_http_status(:created)

        # agora a mais antiga em aberto é a de agosto (vence 10/09)
        make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get)
        invoice = JSON.parse(response.body)["data"]
        expect(invoice["amount"]).to eq(350000)
        expect(invoice["due_date"]).to eq("2026-09-10")
      end
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
      expect(body["data"]["paid_amount"]).to eq(0)
      expect(body["data"]["remaining"]).to eq(350000)
      expect(body["data"]["due_date"]).to eq("2026-09-10")
      expect(body["data"]["paid"]).to eq(false)
    end

    it "aceita reference YYYY-MM e fatura o ciclo do mês anterior, igual ao index" do
      # Nubank (fecha 3, vence 10): setembro fatura o ciclo de agosto [04/08..03/09] = notebook + curso
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { reference: "2026-09" })
      body = JSON.parse(response.body)
      expect(body["data"]["amount"]).to eq(350000)
      expect(body["data"]["due_date"]).to eq("2026-09-10")

      # agosto fatura o ciclo de julho [04/07..03/08] = só a compra pré-fechamento (02/08)
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { reference: "2026-08" })
      expect(JSON.parse(response.body)["data"]["amount"]).to eq(12000)
    end

    it "respeita due_day < closing_day na fatura por mês (casa_card)" do
      # casa_card fecha 25, vence 5: agosto fatura o ciclo de julho [26/06..25/07] → compra de 20/07
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:casa_card).id}/invoice", token: user_token, method: :get, params: { reference: "2026-08" })
      body = JSON.parse(response.body)
      expect(body["data"]["amount"]).to eq(8000)
      expect(body["data"]["due_date"]).to eq("2026-08-05")

      # setembro fatura o ciclo de agosto [26/07..25/08] → compra de 28/07 (pós-fechamento)
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:casa_card).id}/invoice", token: user_token, method: :get, params: { reference: "2026-09" })
      expect(JSON.parse(response.body)["data"]["amount"]).to eq(5000)
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
      body = JSON.parse(response.body)
      expect(body["data"]["paid"]).to eq(true)
      expect(body["data"]["paid_amount"]).to eq(350000)
      expect(body["data"]["remaining"]).to eq(0)
    end

    it "aparece no mês em que foi pago (settled_at), não no do vencimento" do
      # Ciclo de agosto fecha em 03/09 e vence em 10/09; pago (settled) em 15/08.
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15", settled_at: "2026-08-15T10:00:00" })
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      # transaction_date fica no vencimento; settled_at na data do pagamento
      expect(body["data"]["transaction_date"]).to start_with("2026-09")
      expect(body["data"]["settled_at"]).to start_with("2026-08")
      payment_id = body["data"]["id"]

      # Aparece no index de agosto (mês do settled_at)...
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 8, year: 2026 })
      expect(JSON.parse(response.body)["accounts"]["data"].map { |t| t["id"] }).to include(payment_id)

      # ...e não no de setembro (mês do vencimento).
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 9, year: 2026 })
      expect(JSON.parse(response.body)["accounts"]["data"].map { |t| t["id"] }).not_to include(payment_id)
    end

    it "lança um pagamento parcial e reflete o valor pago e o saldo restante" do
      expect {
        make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15", value: 100000 })
      }.to change { accounts(:gabriel_main_account).reload.balance }.by(-100000)
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["data"]["value"]).to eq(100000)

      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { date: "2026-08-15" })
      body = JSON.parse(response.body)
      expect(body["data"]["paid_amount"]).to eq(100000)
      expect(body["data"]["remaining"]).to eq(250000)
      expect(body["data"]["paid"]).to eq(false)
    end

    it "soma pagamentos parciais até quitar a fatura" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15", value: 200000 })
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      expect(response).to have_http_status(:created)
      # segundo pagamento cobre o restante (150000)
      expect(JSON.parse(response.body)["data"]["value"]).to eq(150000)

      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { date: "2026-08-15" })
      expect(JSON.parse(response.body)["data"]["paid"]).to eq(true)
    end

    it "permite pagar acima do saldo restante da fatura (paga a mais)" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15", value: 400000 })
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["data"]["value"]).to eq(400000)

      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { date: "2026-08-15" })
      body = JSON.parse(response.body)
      expect(body["data"]["paid_amount"]).to eq(400000)
      expect(body["data"]["remaining"]).to eq(0)
      expect(body["data"]["paid"]).to eq(true)
    end

    it "permite pagar a mesma fatura novamente informando um valor" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15", value: 50000 })
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["data"]["value"]).to eq(50000)

      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/invoice", token: user_token, method: :get, params: { date: "2026-08-15" })
      # 350000 (primeiro, quitando) + 50000 (segundo) = 400000 pagos
      expect(JSON.parse(response.body)["data"]["paid_amount"]).to eq(400000)
    end

    it "exige um valor explícito ao pagar de novo uma fatura já quitada" do
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      make_request(endpoint: v1_credit_balances_path + "/#{credit_balances(:gabriel_nubank).id}/pay_invoice", token: user_token, method: :post, params: { account_id: accounts(:gabriel_main_account).id, date: "2026-08-15" })
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("Informe um valor de pagamento maior que zero.")
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
