require 'rails_helper'
require 'request_helper'

RSpec.describe V1::Core::VersionController, type: :request do
  include RequestHelper

  describe "GET #show" do
    it "retorna as informações de versão (hash, date, branch)" do
      make_request(endpoint: "/v1/core/version", method: :get)
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)["data"]
      expect(data.keys).to match_array(%w[hash date branch])
      expect(data.values).to all(be_a(String))
    end

    it "usa as variáveis de ambiente do deploy quando presentes" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GIT_COMMIT_HASH').and_return('abc1234')
      allow(ENV).to receive(:[]).with('GIT_COMMIT_DATE').and_return('2026-07-08 12:00:00 -0300')
      allow(ENV).to receive(:[]).with('GIT_BRANCH').and_return('dev')

      make_request(endpoint: "/v1/core/version", method: :get)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["data"]).to eq(
        "hash" => "abc1234",
        "date" => "2026-07-08 12:00:00 -0300",
        "branch" => "dev"
      )
    end

    it "cai nas variáveis do Railway quando as do deploy não estão presentes" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GIT_COMMIT_HASH').and_return(nil)
      allow(ENV).to receive(:[]).with('GIT_BRANCH').and_return(nil)
      allow(ENV).to receive(:[]).with('RAILWAY_GIT_COMMIT_SHA').and_return('railwaysha')
      allow(ENV).to receive(:[]).with('RAILWAY_GIT_BRANCH').and_return('main')

      make_request(endpoint: "/v1/core/version", method: :get)
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)["data"]
      expect(data["hash"]).to eq("railwaysha")
      expect(data["branch"]).to eq("main")
    end

    it "prioriza as variáveis do deploy sobre as do Railway" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('GIT_COMMIT_HASH').and_return('deploysha')
      allow(ENV).to receive(:[]).with('RAILWAY_GIT_COMMIT_SHA').and_return('railwaysha')

      make_request(endpoint: "/v1/core/version", method: :get)
      expect(JSON.parse(response.body)["data"]["hash"]).to eq("deploysha")
    end

    it "exige o token da API (X-API-Key)" do
      get "/v1/core/version"
      expect(response).to have_http_status(:forbidden)
    end
  end
end
