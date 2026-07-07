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
  routes.rb                     # Versionado em /v1
db/
  migrate/
  schema.rb
  seeds.rb
spec/                           # RSpec (request specs + fixtures)
```

## Domínio (modelos principais)

- **User** — usuário do sistema; ao ser criado ganha automaticamente uma carteira padrão ("Minha Carteira") vinculada como `main_user_wallet`.
- **Wallet** — carteira financeira; pertence a um dono (`owner`) e pode ser compartilhada com outros usuários. `total` = soma dos depósitos - soma dos saques.
- **UserWallet** — vínculo entre usuário e carteira; funciona como convite (`accepted` default `false`). O dono é vinculado automaticamente com `accepted: true` na criação da carteira.
- **Transaction** — transação de uma carteira; `kind` é `deposit` ou `withdraw`, `value` em centavos (integer), `transaction_date` é `date`.

Convenções de modelo: usar `discard` (não `destroy`) para exclusão lógica; `paper_trail` para histórico de versões (via `ApplicationRecord`); `dependent_discard` para propagar o soft delete a associações dependentes.

## API

Todas as rotas estão sob `/v1`:

- `/v1/auth` — `sign_in`, `sign_up`, `recover_password`, `reset_password`.
- `/v1/users/me` — dados do usuário autenticado.
- `/v1/wallets` — REST + `GET /v1/wallets/main` (carteira principal). Apenas o dono pode atualizar/remover.
- `/v1/transactions` — REST; `index` exige `wallet_id` e aceita `start_date`/`end_date`, retornando o saldo do período em `total`.
- `/v1/user_wallets` — convites: `index` (pendentes do usuário), `create` (dono convida por e-mail), `POST :id/accept`, `POST :id/reject`.
- `/v1/core/options/:entity/:type` — opções traduzidas de enums (ex.: `transaction/kind`).

Respostas em JSON seguem o envelope `{ data: ... }` para sucesso e `{ message: "..." }` para erros e ações. Listagens são paginadas (`page`, `per_page`) com `total_count`/`total_pages` no envelope.

## Autenticação

- Todas as requisições exigem o token fixo da API no header `X-API-Key`.
- Login via `POST /v1/auth/sign_in` — retorna JWT (expiração de 7 dias).
- Demais endpoints exigem o JWT no header `Authorization: Bearer`.
- Devise está configurado, mas o fluxo de sessão é stateless (JWT).

## Banco de dados

- **Multi-schema**: todos os ambientes usam o mesmo banco (`POSTGRES_DB`, default `my_finance_api`), isolados por schema do Postgres via `POSTGRES_SCHEMA` (ex.: `dev`, `prod`) — configurado com `schema_search_path` no `database.yml`. Cada schema tem sua própria `schema_migrations`. A task `db:ensure_schema` (encadeada em `db:migrate`/`db:schema:load`) cria o schema automaticamente se não existir. O ambiente de teste usa banco separado (`my_finance_api_test`, schema `public`).
- Chaves primárias em `uuid` (`gen_random_uuid()`), configurado como padrão nos generators (`primary_key_type: :uuid`).
- Migrations em `db/migrate/`; schema atual em `db/schema.rb` — o dump é agnóstico de schema (`dump_schemas` + initializer `schema_dumper.rb`), então não fixa o nome do schema do ambiente.
- **Migração do banco legado (Nest/MikroORM)**: `bin/rails nest:migrate` converte in-place o schema do ambiente atual para a estrutura Rails via ALTER TABLE (sem copiar dados), estampando a `schema_migrations`. Transacional e idempotente. Ver `lib/tasks/nest_migration.rake`.
- Soft delete via coluna `discarded_at` em todas as tabelas de domínio.
- Índices únicos compostos com `discarded_at` (ex.: `users` por `email/discarded_at`, `user_wallets` por `user_id/wallet_id/discarded_at`).
- Valores monetários em centavos (integer).

## Ambiente de desenvolvimento

Subir via Docker Compose:

```bash
docker-compose up
```

Containers: `db` (Postgres 15.4), `web` (Rails na porta `${VIRTUAL_PORT}`), `nginx`. O `.env` controla `API_FIXED_TOKEN`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_SCHEMA`, `VIRTUAL_PORT`. Timezone fixada em `America/Sao_Paulo`.

Sem Docker:

```bash
bundle install
bin/rails db:setup
bin/rails s
```

## Testes

```bash
bundle exec rspec
```

- **RSpec** como framework principal (request specs com fixtures em `spec/fixtures/`).
- Use o módulo `RequestHelper` (`make_request`) que já injeta `X-API-Key` e `Authorization`.
- Helpers de token: `user_token` (usuário 1), `second_user_token` (usuário 2), `expired_token`, `invalid_token`.
- **SimpleCov** gera relatório em `coverage/`.

## Convenções

- Código em inglês (nomes de classes, métodos, variáveis, migrations, commits).
- Comentários e mensagens de erro voltadas ao usuário podem ficar em pt-BR.
- Não usar `destroy` direto em models com `discard`; usar `record.discard`.
- Filtros, escopos e queries seguem o padrão Rails (`scope :active, -> { ... }`) — preferir `where` explícito a métodos mágicos quando houver soft delete envolvido (default scope não se aplica em `joins`).
- Para paginação usar o helper `paginate(record, page, per_page)` (ApplicationHelper) e expor metadados de paginação no envelope JSON.
- Para busca textual usar `search_bar(record, terms, campos)` (unaccent + ILIKE).

## Clientes

As interfaces deste backend são o app mobile em `../my-finance-app` (React Native) e o webapp em `../my-finance-webapp` (Vite + React + TypeScript). Ambos consomem as rotas `/v1/*`.
