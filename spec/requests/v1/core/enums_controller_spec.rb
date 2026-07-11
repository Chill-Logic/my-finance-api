require 'rails_helper'
require 'request_helper'

RSpec.describe V1::Core::EnumsController, type: :request do
  fixtures :all
  include RequestHelper

  describe "GET #options" do
    it "retorna as opções traduzidas de um enum" do
      make_request(endpoint: "/v1/core/enums/options/transaction/kind", method: :get)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"]).to match_array([
        { "value" => "deposit", "label" => "Depósito" },
        { "value" => "withdraw", "label" => "Saque" }
      ])
    end

    it "retorna erro para enum inválido" do
      make_request(endpoint: "/v1/core/enums/options/transaction/any", method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to include("O enum any não foi encontrado")
    end

    it "retorna erro para entidade inválida" do
      make_request(endpoint: "/v1/core/enums/options/any/kind", method: :get)
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["message"]).to eq("A entidade any não foi encontrada.")
    end
  end
end
