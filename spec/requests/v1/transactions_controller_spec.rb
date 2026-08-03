require 'rails_helper'
require 'request_helper'

RSpec.describe V1::TransactionsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #index" do
    it "separa Conta e Cartões em listas e totais próprios" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 7, year: 2026 })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      # Conta: salário, mercado, pendente e rascunho
      expect(body["accounts"]["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:salary).id, transactions(:market).id, transactions(:pending_bill).id, transactions(:draft_plan).id])
      expect(body["accounts"]["total_count"]).to eq(4)
      # 500000 (salário) - 35000 (mercado); pendente e rascunho fora do efetivado
      expect(body["accounts"]["total_settled"]).to eq(465000)
      # inclui a pendente (-20000); rascunho continua fora
      expect(body["accounts"]["total_projected"]).to eq(445000)

      # Cartões: crédito mostra o ciclo faturado no mês (o anterior). Julho fatura o ciclo
      # de junho do Nubank ([04/06..03/07]), que está vazio.
      expect(body["credits"]["data"]).to eq([])
      expect(body["credits"]["total_count"]).to eq(0)
      expect(body["credits"]["total_settled"]).to eq(0)
    end

    it "no crédito mostra o ciclo faturado no mês (o anterior), não o que se está gastando" do
      # Agosto fatura o ciclo de julho do Nubank ([04/07..03/08]) → só a compra de 02/08
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 8, year: 2026 })
      body = JSON.parse(response.body)
      expect(body["credits"]["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:nubank_pre_fechamento).id])
      expect(body["credits"]["total_settled"]).to eq(-12000)

      # Setembro fatura o ciclo de agosto ([04/08..03/09]) → notebook (05/08) e curso (10/08)
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 9, year: 2026 })
      body = JSON.parse(response.body)
      expect(body["accounts"]["data"]).to eq([])
      expect(body["credits"]["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:nubank_notebook).id, transactions(:nubank_curso).id])
      expect(body["credits"]["total_count"]).to eq(2)
      expect(body["credits"]["total_settled"]).to eq(-350000)
      expect(body["credits"]["total_projected"]).to eq(-350000)
    end

    it "usa o ramo due_day < closing_day no ciclo faturado (casa_card fecha 25)" do
      # Agosto fatura o ciclo de julho ([26/06..25/07]) → só a compra de 20/07 (antes do fechamento)
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:casa).id, month: 8, year: 2026 })
      body = JSON.parse(response.body)
      expect(body["credits"]["data"].map { |t| t["id"] }).to match_array([transactions(:casa_card_before_closing).id])
      expect(body["credits"]["total_settled"]).to eq(-8000)

      # Setembro fatura o ciclo de agosto ([26/07..25/08]) → a compra de 28/07 (depois do fechamento)
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:casa).id, month: 9, year: 2026 })
      body = JSON.parse(response.body)
      expect(body["credits"]["data"].map { |t| t["id"] }).to match_array([transactions(:casa_card_after_closing).id])
      expect(body["credits"]["total_settled"]).to eq(-5000)
    end

    it "bucketiza pelo settled_at: transação paga adiantada cai no mês do pagamento" do
      # early_paid_bill vence em out/2026 mas foi paga em mai/2026 (carteira casa)
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:casa).id, month: 5, year: 2026 })
      expect(JSON.parse(response.body)["accounts"]["data"].map { |t| t["id"] }).to include(transactions(:early_paid_bill).id)

      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:casa).id, month: 10, year: 2026 })
      expect(JSON.parse(response.body)["accounts"]["data"].map { |t| t["id"] }).not_to include(transactions(:early_paid_bill).id)
    end

    it "aceita o parâmetro reference no formato YYYY-MM" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, reference: "2026-06" })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["accounts"]["data"].map { |transaction| transaction["id"] }).to match_array([transactions(:old_deposit).id])
      expect(body["accounts"]["total_settled"]).to eq(10000)
      expect(body["accounts"]["total_projected"]).to eq(10000)
    end

    it "filtra por origem quando source_type/source_id são enviados" do
      make_request(endpoint: v1_transactions_path, token: user_token, method: :get, params: { wallet_id: wallets(:gabriel_main).id, month: 7, year: 2026, source_type: "Account", source_id: accounts(:gabriel_main_account).id })
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["accounts"]["data"].length).to eq(4)
      expect(body["accounts"]["total_settled"]).to eq(465000)
      expect(body["credits"]["data"]).to eq([])
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
      # conta nasce pendente (settle é manual)
      expect(body["data"]["settled"]).to eq(false)
      expect(body["data"]["settled_at"]).to be_nil
    end

    it "cria uma transação num saldo de crédito apontando o cartão" do
      params = { transaction: { description: "iFood", value: 8000, kind: "withdraw", transaction_date: "2026-07-06", source_type: "CreditBalance", source_id: credit_balances(:gabriel_nubank).id, credit_card_id: credit_cards(:gabriel_nubank_fisico).id } }
      make_request(endpoint: v1_transactions_path, token: user_token, method: :post, params: params)
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["data"]["source_type"]).to eq("CreditBalance")
      expect(body["data"]["credit_card_id"]).to eq(credit_cards(:gabriel_nubank_fisico).id)
      expect(body["data"]["wallet_id"]).to eq(wallets(:gabriel_main).id)
      # crédito nasce settled automaticamente, com settled_at = transaction_date
      expect(body["data"]["settled"]).to eq(true)
      expect(body["data"]["settled_at"]).to eq(body["data"]["transaction_date"])
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
