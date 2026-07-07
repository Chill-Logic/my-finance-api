# My Finance API

API do My Finance — sistema de controle de finanças pessoais com carteiras compartilháveis.

## Versões utilizadas

- Ruby 3.2.2
- Rails 8.1

## Bibliotecas utilizadas

- [Devise](devise-link) - para autenticação dos usuários
- [JWT](jwt-link) - para tokens de autenticação stateless
- [Active Model Serializers](ams-link) - para renderizar os objetos JSON
- [Discard](discard-link) - para exclusão lógica (soft delete)
- [Papertrail (gem)](papertrail-gem-link) - para salvar as versões dos objetos
- [WillPaginate](will-paginate-link) - para paginação customizada

## Arquitetura do projeto

O projeto tem seu ambiente de desenvolvimento usando Docker, para simplificar o processo de configuração dos ambientes entre os membros da equipe.

```bash
cp .env.example .env # preencher as variáveis
make build           # sobe db + web + nginx
make setup           # cria o banco, roda migrações e seeds
```

Sem Docker:

```bash
bundle install
bin/rails db:setup
bin/rails s
```

## Banco de Dados

PostgreSQL 15.4 com a extensão `unaccent` (busca insensível a acentos). Todas as tabelas usam soft delete via coluna `discarded_at`.

Modelos principais: `User`, `Wallet`, `UserWallet` (vínculo/convite entre usuário e carteira) e `Transaction` (depósitos e saques, valores em centavos).

## Testes

```bash
bundle exec rspec
```

O projeto tem cobertura de testes de requisição (request specs) para todos os endpoints, usando RSpec com fixtures e SimpleCov para relatório de cobertura em `coverage/`.

## Documentação

A documentação da API é servida pelo Swagger UI em `/api-docs` ([rswag-api](rswag-link) + [rswag-ui](rswag-link)), protegida por HTTP Basic (`SWAGGER_USERNAME`/`SWAGGER_PASSWORD` no `.env`).

Os specs OpenAPI 3.0 são escritos à mão em `public/api-docs/v1/*.yaml` (um arquivo por recurso) e registrados em `config/initializers/rswag_ui.rb`. O template `swagger/index.erb` customiza o UI para aplicar automaticamente o token JWT retornado pelo login no botão Authorize.

[devise-link]:https://github.com/heartcombo/devise
[jwt-link]:https://github.com/jwt/ruby-jwt
[ams-link]:https://github.com/rails-api/active_model_serializers
[discard-link]:https://github.com/jhawthorn/discard
[papertrail-gem-link]:https://github.com/paper-trail-gem/paper_trail
[will-paginate-link]:https://github.com/mislav/will_paginate
[rswag-link]:https://github.com/rswag/rswag
