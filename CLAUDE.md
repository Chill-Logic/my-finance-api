# My Finance API

API do My Finance, sistema de controle de finanças pessoais. Backend Rails que gerencia usuários, carteiras (`wallets`) compartilháveis entre usuários via convites (`user_wallets`) e transações (`transactions`) de depósito/saque.

## Stack

- **Ruby** 3.2.2
- **Rails** 8.1 (modo API)
- **PostgreSQL** 15.4 (com extensões `plpgsql` e `unaccent`)
- **Puma** 6.4
- **Docker** + `docker-compose` para o ambiente de desenvolvimento

## Bibliotecas-chave

- **Devise** + **JWT** — autenticação de usuários
- **PaperTrail** — versionamento de objetos
- **Discard** — soft delete (`discarded_at`)
- **active_model_serializers** — serialização JSON
- **will_paginate** — paginação
- **rack-cors** — CORS para os clientes (app e webapp)
- **rswag-api** + **rswag-ui** — Swagger UI e documentação OpenAPI
- **dotenv-rails** — variáveis de ambiente em dev
- **RSpec**, **WebMock**, **SimpleCov** — testes

## Estrutura

```
app/
  controllers/
    application_controller.rb   # autenticação (X-API-Key + JWT)
    concerns/                   # ExceptionHandler, JsonWebToken
    v1/
      auths_controller.rb       # sign_in, sign_up, recover/reset password
      users_controller.rb       # GET /v1/users/me
      wallets_controller.rb
      transactions_controller.rb
      user_wallets_controller.rb  # convites de carteira
      core/                     # Endpoints utilitários (enums etc.)
  models/                       # Domínio (ver abaixo)
  serializers/                  # active_model_serializers (1 por modelo)
config/
  routes.rb                     # Versionado em /v1; /api-docs (Swagger) atrás de login por formulário
db/
  migrate/
  schema.rb
  seeds.rb
public/api-docs/v1/             # Specs OpenAPI escritos à mão (1 yaml por recurso)
swagger/index.erb               # Template customizado do Swagger UI
spec/                           # RSpec (request specs + fixtures)
```

## Domínio (modelos principais)

- **User** — usuário do sistema; ao ser criado ganha automaticamente uma carteira padrão ("Minha Carteira") vinculada como `main_user_wallet`.
- **Wallet** — carteira financeira; pertence a um dono (`owner`) e pode ser compartilhada com outros usuários. `total` = soma dos depósitos - soma dos saques.
- **UserWallet** — vínculo entre usuário e carteira; funciona como convite (`accepted` default `false`). O dono é vinculado automaticamente com `accepted: true` na criação da carteira.
- **Transaction** — transação de uma carteira; `kind` é `deposit` ou `withdraw`, `value` em centavos (integer), `transaction_date` é `datetime` (hoje os clientes mandam só a data — cast para meia-noite no fuso da app; o tipo já comporta hora no futuro). Os filtros `from_date`/`to_date` usam os limites do dia no fuso da app por padrão; o `index` aceita `timezone` opcional (nome IANA) para usar o dia local do cliente.

Convenções de modelo: usar `discard` (não `destroy`) para exclusão lógica; `paper_trail` para histórico de versões (via `ApplicationRecord`); `dependent_discard` para propagar o soft delete a associações dependentes.

## API

Todas as rotas estão sob `/v1`:

- `/v1/auth` — `sign_in`, `sign_up`, `recover_password`, `reset_password`.
- `/v1/users/me` — dados do usuário autenticado.
- `/v1/wallets` — REST + `GET /v1/wallets/main` (carteira principal). Apenas o dono pode atualizar/remover.
- `/v1/transactions` — REST; `index` exige `wallet_id` e aceita `start_date`/`end_date`, retornando o saldo do período em `total`.
- `/v1/user_wallets` — convites: `index` (pendentes do usuário), `create` (dono convida por e-mail), `POST :id/accept`, `POST :id/reject`.
- `/v1/core/enums/options/:entity/:type` — opções traduzidas de enums (ex.: `transaction/kind`).

Respostas em JSON seguem o envelope `{ data: ... }` para sucesso e `{ message: "..." }` para erros e ações. Listagens são paginadas (`page`, `per_page`) com `total_count`/`total_pages` no envelope.

## Documentação (Swagger)

- Swagger UI em `/api-docs`, protegido por **login em formulário** (não HTTP Basic — o prompt nativo do navegador não é oferecido ao gerenciador de senhas). O middleware `SwaggerAuth` (`lib/swagger_auth.rb`, registrado em `config/application.rb`) valida `SWAGGER_USERNAME`/`SWAGGER_PASSWORD` (do `.env`), mantém a sessão num cookie assinado (`secret_key_base`, 12h), serve o logo em `/api-docs/logo` (wordmark, tela de login) e `/api-docs/logo-icon` (ícone, header do UI), e tem `/api-docs/logout`. Login inválido reexibe o form com 200 (401 quebraria por causa do Warden do Devise).
- Os specs OpenAPI 3.0 são **escritos à mão** em `public/api-docs/v1/*.yaml` (um arquivo por recurso: `auth.yaml`, `wallets.yaml`, `transactions.yaml`, `user_wallets.yaml`) e registrados em `config/initializers/rswag_ui.rb` — não usamos rswag-specs/geração automática. Ao alterar um endpoint, atualize o YAML correspondente.
- O template `swagger/index.erb` customiza o UI: persiste o Authorize, aplica automaticamente o token retornado pelo `POST /v1/auth/sign_in` (`data.token`), lembra o servidor selecionado e aplica a identidade visual do My Finance (header escuro `#052131` com logo e botão "Sair", acento verde-oliva `#88a15e`, topbar padrão escondida, código da doc em navy no lugar do roxo padrão). A paleta segue o e-mail de redefinição de senha (`app/views/devise/mailer/`). No topo da doc há uma faixa com a versão do build (branch/commit/data) via `VersionInfo` (`lib/version_info.rb`), o mesmo módulo usado pelo `GET /v1/core/version` — lê as envs `GIT_*` do deploy com fallback pro git ao vivo.

## Autenticação e autorização

- Todas as requisições exigem o token fixo da API no header `X-API-Key`.
- Login via `POST /v1/auth/sign_in` — retorna JWT (expiração de 7 dias).
- Demais endpoints exigem o JWT no header `Authorization: Bearer`.
- Fluxo no `ApplicationController`: `authenticate_fixed_token!` → `authenticate_user!` (popula `@current_user`). O encode/decode do JWT vive no concern `app/controllers/concerns/json_web_token.rb`.
- Erros de JWT (`ExceptionHandler::DecodeError`, `ExceptionHandler::ExpiredSignature`) têm rescue automático no `ExceptionHandler` e viram resposta JSON 401.
- Devise está configurado, mas o fluxo de sessão é stateless (JWT).
- **Autorização por recurso**: o acesso a carteiras (e tudo que pende delas) passa pelo escopo `Wallet.accessible_by(user)` (vínculo `user_wallets` aceito); ações de dono (`update`/`destroy` de carteira, convites) exigem `owner_id == @current_user.id` e retornam 403 caso contrário.

## Banco de dados

- **Migração do banco legado (Nest/MikroORM)**: `bin/rails nest:migrate` converte in-place o schema do ambiente atual para a estrutura Rails via ALTER TABLE (sem copiar dados), estampando a `schema_migrations`. Transacional e idempotente. Ver `lib/tasks/nest_migration.rake`.
- **Multi-schema**: todos os ambientes usam o mesmo banco (`POSTGRES_DB`, default `my_finance_api`), isolados por schema do Postgres via `POSTGRES_SCHEMA` (ex.: `dev`, `prod`) — configurado com `schema_search_path` no `database.yml`. Cada schema tem sua própria `schema_migrations`. A task `db:ensure_schema` (encadeada em `db:migrate`/`db:schema:load`) cria o schema automaticamente se não existir. O ambiente de teste usa banco separado (`my_finance_api_test`, schema `public`).
- Chaves primárias em `uuid` (`gen_random_uuid()`), configurado como padrão nos generators (`primary_key_type: :uuid`).
- Migrations em `db/migrate/`; schema atual em `db/schema.rb` — o dump é agnóstico de schema (`dump_schemas` + initializer `schema_dumper.rb`), então não fixa o nome do schema do ambiente.
- Soft delete via coluna `discarded_at` em todas as tabelas de domínio.
- Índices únicos compostos com `discarded_at` (ex.: `users` por `email/discarded_at`, `user_wallets` por `user_id/wallet_id/discarded_at`).
- Valores monetários em centavos (integer).
- Auditoria via PaperTrail: `has_paper_trail` vem do `ApplicationRecord` e o autor da mudança é registrado pelo `set_paper_trail_whodunnit` no controller.

## Ambiente de desenvolvimento

Sem Docker:

```bash
bundle install
bin/rails db:setup
bin/rails s
```

Subir via Docker Compose:

```bash
docker-compose up
```

Containers: `db` (Postgres 15.4), `web` (Rails na porta `${VIRTUAL_PORT}`), `nginx`. O `.env` controla `API_FIXED_TOKEN`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_SCHEMA`, `VIRTUAL_PORT`. Timezone fixada em `America/Sao_Paulo`.

## Deploy

- **Dev**: push na branch `dev` dispara `.github/workflows/deploy-dev.yml` — rsync do código via SSH por Cloudflare Tunnel (`cloudflared access ssh`, sem Access/login na frente; a autenticação é a chave SSH), escrita do `.env` a partir do secret `ENV_FILE_DEV`, e `bin/deploy_server.sh` no servidor (bundle + migrations + restart do serviço systemd de usuário, que relê o `.env`; o script cria o serviço na primeira execução). Secrets: `SSH_PRIVATE_KEY`, `REMOTE_USER`, `REMOTE_HOST`, `ENV_FILE_DEV`. O servidor roda o app sem Docker (mise + puma sob systemd; logs via `journalctl --user -u my-finance-api`).
- Deploy manual dos arquivos: `./local-config.sh <user> <host>` (só rsync, sem restart).

## Testes

```bash
bundle exec rspec
```

- **RSpec** como framework principal (request specs com fixtures em `spec/fixtures/`).
- Use o módulo `RequestHelper` (`make_request`) que já injeta `X-API-Key` e `Authorization`.
- Helpers de token: `user_token` (usuário 1), `second_user_token` (usuário 2), `expired_token`, `invalid_token`.
- **SimpleCov** gera relatório em `coverage/`.

## Padrões de código

- **Toda feature nova ou alteração de endpoint deve vir acompanhada de: (1) request specs criados/atualizados cobrindo sucesso e erros, e (2) o YAML do Swagger correspondente em `public/api-docs/v1/` criado/atualizado (endpoint novo em arquivo novo também entra no `config/initializers/rswag_ui.rb`). A entrega só está completa com `bundle exec rspec` verde.**
- Código em inglês (nomes de classes, métodos, variáveis, migrations, commits).
- Comentários e mensagens de erro voltadas ao usuário podem ficar em pt-BR.

### Controllers

Namespace `V1::` para versionamento; `V1::Core::` para utilitários públicos sem JWT (enums). Estrutura padrão — retornos antecipados para os erros, render de sucesso sempre por último:

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

Os `set_*` de before_action buscam com `find_by` dentro do escopo acessível e renderizam `{ message: '... não encontrada.' }` 422 quando nil.

### Respostas e status

- Sucesso: `{ data: resource }`; ações e erros: `{ message: "..." }`; erro de validação: `model.errors.full_messages.join(', ')`.
- Status: 200 (OK), 201 (Created), 422 (validação e não-encontrado), 401 (JWT ausente/inválido/expirado), 403 (`X-API-Key` ausente/inválido e ações restritas ao dono).

### Enums traduzidos

```ruby
# No model
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

No serializer, inclua `TranslatableEnums` e some `translatable_enums(:kind)` aos attributes — expõe `translated_kind`. As opções ficam públicas em `GET /v1/core/enums/options/:entity/:type` (reflexão via `ApplicationHelper.enum_options`).

### Serializers

Um serializer por model em `app/serializers/`; `ApplicationRecord#serializable_hash` resolve o serializer pelo nome da classe (`WalletSerializer` para `Wallet`).

### Paginação e busca

- `paginate(record, page, per_page, serializer = nil, current_user = nil, **extra_params)` (ApplicationHelper) — retorna o envelope `{ data:, total_count:, total_pages: }`; `**extra_params` adiciona dados extras ao envelope (ex.: `total` do saldo em transactions).
- `search_bar(record, terms, campos)` — busca textual com unaccent + ILIKE em um ou vários campos.

### Soft delete

- Não usar `destroy` em models com `discard`; usar `record.discard` e escopos `.kept`.
- `dependent_discard :associacao` (ApplicationRecord) propaga discard/undiscard para associações dependentes.
- Ao descartar um `User`, o email ganha prefixo com timestamp para liberar a constraint única de email.
- Em `joins`/`includes` de associação o default scope do model associado é aplicado na condição do JOIN (Rails 6+) — só joins com SQL cru ou `unscoped` exigem filtrar `discarded_at` manualmente.
- Filtros, escopos e queries seguem o padrão Rails (`scope :active, -> { ... }`).

## Clientes

As interfaces deste backend são o app mobile em `../my-finance-app` (React Native) e o webapp em `../my-finance-webapp` (Vite + React + TypeScript). Ambos consomem as rotas `/v1/*`.
