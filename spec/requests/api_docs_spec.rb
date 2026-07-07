require 'rails_helper'

RSpec.describe "Swagger API Docs", type: :request do
  before do
    ENV['SWAGGER_USERNAME'] = 'docs'
    ENV['SWAGGER_PASSWORD'] = 'docs-secret'
  end

  it "exige HTTP Basic para acessar a documentação" do
    get "/api-docs/index.html"
    expect(response).to have_http_status(:unauthorized)
  end

  it "serve o Swagger UI com credenciais válidas" do
    get "/api-docs/index.html", headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials('docs', 'docs-secret') }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("My Finance API Docs")
  end

  it "serve os arquivos OpenAPI configurados no rswag-ui" do
    auth = { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials('docs', 'docs-secret') }
    Rswag::Ui.config.config_object[:urls].each do |endpoint|
      get endpoint[:url], headers: auth
      expect(response).to have_http_status(:ok), "esperava 200 para #{endpoint[:url]}"
    end
  end
end
