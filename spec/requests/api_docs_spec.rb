require 'rails_helper'

RSpec.describe "Swagger API Docs", type: :request do
  before do
    ENV['SWAGGER_USERNAME'] = 'docs'
    ENV['SWAGGER_PASSWORD'] = 'docs-secret'
  end

  def sign_in_docs
    post "/api-docs/login", params: { username: 'docs', password: 'docs-secret' }
  end

  it "exibe o formulário de login (e não a doc) quando não autenticado" do
    get "/api-docs/index.html"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="password"')
    expect(response.body).not_to include('swagger-ui-bundle.js')
  end

  it "serve o logo publicamente para a tela de login" do
    get "/api-docs/logo"
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('image/png')
  end

  it "reexibe o formulário com erro para credenciais inválidas" do
    post "/api-docs/login", params: { username: 'docs', password: 'errado' }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('inválidos')
    expect(response.body).to include('name="password"')
  end

  it "autentica com credenciais válidas e serve o Swagger UI" do
    sign_in_docs
    expect(response).to have_http_status(:found)

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("My Finance API Docs")
  end

  it "serve os arquivos OpenAPI configurados no rswag-ui quando autenticado" do
    sign_in_docs
    Rswag::Ui.config.config_object[:urls].each do |endpoint|
      get endpoint[:url]
      expect(response).to have_http_status(:ok), "esperava 200 para #{endpoint[:url]}"
    end
  end

  it "encerra a sessão no logout" do
    sign_in_docs
    get "/api-docs/logout"
    expect(response).to have_http_status(:found)

    get "/api-docs/index.html"
    expect(response.body).to include('name="password"')
    expect(response.body).not_to include('swagger-ui-bundle.js')
  end
end
