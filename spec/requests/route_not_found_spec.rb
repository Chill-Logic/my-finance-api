require 'rails_helper'
require 'request_helper'

RSpec.describe "Rotas não reconhecidas", type: :request do
  fixtures :all
  include RequestHelper

  it "retorna JSON 404 legível para rota inexistente" do
    make_request(endpoint: "/v1/rota-que-nao-existe", token: user_token, method: :get)

    expect(response).to have_http_status(:not_found)
    body = JSON.parse(response.body)
    expect(body["message"]).to include("Rota não encontrada")
    expect(body["message"]).to include("/v1/rota-que-nao-existe")
  end

  it "não vaza existência de rota para requisição sem token" do
    make_request(endpoint: "/v1/rota-que-nao-existe", method: :get)

    expect(response).to have_http_status(:unauthorized)
  end
end
