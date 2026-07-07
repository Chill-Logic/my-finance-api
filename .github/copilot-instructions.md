# My Finance API - Instruções para Assistente de Código IA

## Visão Geral do Projeto
Esta é uma aplicação Rails 8.1 somente API para o sistema My Finance, gerenciando usuários, carteiras compartilháveis e transações financeiras. Cada usuário nasce com uma carteira padrão e pode compartilhar carteiras com outros usuários via convites.

## Padrões Arquiteturais Principais

### Autenticação e Autorização
- **Dupla Autenticação**: Todas as requisições requerem tanto token API fixo (`X-API-Key` header) quanto token JWT de usuário (`Authorization: Bearer` header)
- **Implementação JWT**: Módulo JWT customizado em `app/controllers/concerns/json_web_token.rb` com expiração de 7 dias
- **Fluxo de Autenticação**: `ApplicationController` → `authenticate_fixed_token!` → `authenticate_user!`
- **Autorização por Recurso**: O acesso a carteiras passa pelo escopo `Wallet.accessible_by(user)` (vínculo `user_wallets` aceito); ações de dono (`update`/`destroy` de carteira, convites) exigem `owner_id == @current_user.id`

### Padrão de Exclusão Lógica
- **Gem Discard**: Todos os models usam `include Discard::Model` com `default_scope -> { kept }`
- **Modificação de Email**: Ao descartar usuário, email recebe prefixo com timestamp para evitar problemas de constraint única
- **Propagação**: `dependent_discard :associacao` (definido em `ApplicationRecord`) propaga discard/undiscard para associações dependentes
- **Escopo Customizado**: Sempre use `.kept` ou trate registros descartados explicitamente; em `joins` o default scope do model associado NÃO se aplica — adicione `discarded_at: nil` explícito

### Estrutura da API e Controllers
- **Convenção de Namespace**: `V1::` para versionamento; `V1::Core::` para utilitários públicos (enums)
- **Endpoints de Enum**: `GET /v1/core/enums/options/:entity/:type` usando reflexão de `ApplicationHelper.enum_options`

### Banco de Dados e Models
- **Enums**: Definidos nos models como `enum :kind, ["deposit", "withdraw"].index_with(&:itself)`, com labels traduzidos em `config/locales/pt-BR.yml` (`activerecord.attributes.<model>.<enum_plural>.<value>`)
- **Multi-schema**: Todos os ambientes compartilham o mesmo banco, isolados por schema do Postgres (`POSTGRES_SCHEMA` → `schema_search_path` no `database.yml`); a task `db:ensure_schema` cria o schema antes de `db:migrate`/`db:schema:load`. O `public` fica no final do search_path para resolver as extensões
- **Extensões PostgreSQL**: Usa extensão `unaccent` para busca insensível a acentos (instalada no schema `public`)
- **Auditoria**: Gem PaperTrail rastreia todas as mudanças de model via `set_paper_trail_whodunnit`
- **Chaves primárias**: `uuid` em todos os models (`primary_key_type: :uuid` nos generators; `type: :uuid` nas references de migrations)
- **Dinheiro**: Valores monetários sempre em centavos (integer)

## Fluxos de Desenvolvimento

### Testes com RSpec
- **Executar Testes**: `bundle exec rspec`
- **Teste de Requisição**: Use módulo `RequestHelper` com método `make_request` para teste de API
- **Helpers de Token**: Métodos `user_token`, `second_user_token`, `expired_token`, `invalid_token` disponíveis
- **Fixtures**: Localizados em `spec/fixtures/` para dados de teste

### Operações de Banco de Dados
- **Migrations**: Padrão Rails padrão, note a configuração da extensão unaccent
- **Seeds**: `db/seeds.rb` para dados iniciais
- **Schema**: `db/schema.rb` auto-gerado mostra estrutura atual

### Desenvolvimento Docker
- **Inicialização**: `docker-compose up` inicia PostgreSQL + Rails + Nginx (ou use os alvos do `Makefile`)
- **Ambiente**: Usa arquivo `.env` para configuração
- **Banco de Dados**: PostgreSQL 15.4 com configuração de porta customizada

## Helpers e Utilitários Principais

### Paginação e Busca
- **ApplicationHelper#paginate**: Paginação customizada com parâmetros `page`, `per_page`, suporta serializers e `**extra_params` para dados extras no envelope (ex.: `total` do saldo)
- **ApplicationHelper#search_bar**: Busca baseada em unaccent do PostgreSQL através de múltiplos campos

## Tratamento de Erros e Convenções

### Padrões de Exceção
- **Exceções Customizadas**: `ExceptionHandler::DecodeError`, `ExceptionHandler::ExpiredSignature`
- **Erros JWT**: Rescue automático e respostas JSON de erro
- **Erros de Validação**: Retornar formato `{ message: model.errors.full_messages.join(', ') }`

### Convenções de Resposta
- **Sucesso**: `{ data: resource }` ou `{ message: "Mensagem de sucesso" }`
- **Erros**: `{ message: "Mensagem de erro" }`
- **Códigos de Status**: 200 (OK), 201 (Created), 422 (Unprocessable Entity), 401 (Unauthorized), 403 (Forbidden)

## Padrões Comuns a Seguir

### Estrutura de Controller
```ruby
class V1::ExamplesController < ApplicationController
  before_action :set_resource, only: [:show, :update, :destroy]

  def index
    @resources = Model.accessible_by(@current_user)
    @resources = search_bar(@resources, params[:terms], ["searchable_field"])
    @resources = paginate(@resources, params[:page], params[:per_page])
    render json: @resources, status: :ok
  end

  def show
    render json: { data: @resource }, status: :ok
  end

  def create
    @resource = Model.new(resource_params)

    return render json: { message: @resource.errors.full_messages.join(', ') }, status: :unprocessable_entity unless @resource.save

    render json: { data: @resource }, status: :created
  end

  def update
    return render json: { message: @resource.errors.full_messages.join(', ') }, status: :unprocessable_entity unless @resource.update(resource_params)

    render json: { data: @resource }, status: :ok
  end

  def destroy
    return render json: { message: @resource.errors.full_messages.join(', ') }, status: :unprocessable_entity unless @resource.discard

    render json: { message: 'Recurso removido com sucesso!' }, status: :ok
  end
end
```

### Enums de Model
```ruby
# No Model
enum :kind, ["deposit", "withdraw"].index_with(&:itself)
```

```yaml
# Em config/locales/pt-BR.yml
pt-BR:
  activerecord:
    attributes:
      transaction:
        kinds:
          deposit: "Depósito"
          withdraw: "Saque"
```

### Serializers
Um serializer por model em `app/serializers/`; `ApplicationRecord#serializable_hash` resolve o serializer pelo nome da classe. Para enums traduzidos, inclua `TranslatableEnums` e adicione `translatable_enums(:campo)` aos attributes.

Sempre prefira fazer retornos antecipados para lançamento de erros deixando o render de sucesso ao final para evitar complexidade ciclomática, use soft deletion e siga o padrão de enums traduzidos via locale para internacionalização sustentável.
