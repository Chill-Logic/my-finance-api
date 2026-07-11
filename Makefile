rails_container="my-finance-api-web-1"

.DEFAULT_GOAL := help

.PHONY: help
help: ## Mostra os comandos disponíveis
	@awk 'BEGIN { \
		FS = ":.*"; \
		print "Comandos disponíveis:"; \
	} \
	/^# / { section = substr($$0, 3); next } \
	/^[a-zA-Z0-9_-]+:/ { \
		if (section) { printf "\n\033[1m%s\033[0m\n", section; section = "" } \
		desc = ""; \
		if (match($$0, /## /)) desc = substr($$0, RSTART + 3); \
		printf "  \033[36m%-16s\033[0m %s\n", $$1, desc; \
	}' $(MAKEFILE_LIST)

# Local commands

.PHONY: sidekiq
sidekiq: ## Roda o sidekiq localmente (precisa do redis local)
	@bundle exec sidekiq

# Docker generic commands

.PHONY: exec
exec: ## Executa um comando num container (uso: make exec service=... cmd=...)
	@docker exec -it $(service) $(cmd)

.PHONY: attached
attached: ## Anexa ao terminal de um container (uso: make attached service=...)
	@docker attach $(service)

# Docker specific commands

.PHONY: start
start: ## Sobe o docker-compose (apenas executa)
	@docker compose up --remove-orphans $(options)

.PHONY: build
build: ## Sobe o docker-compose com --build
	@$(MAKE) start options="--build"

.PHONY: attach
attach: ## Anexa ao container do backend
	@$(MAKE) attached service="$(rails_container)"

.PHONY: start-attach
start-attach: ## Sobe em segundo plano e anexa ao container
	@$(MAKE) start options="-d"
	@$(MAKE) attached service="$(rails_container)"

.PHONY: bash
bash: ## Abre o bash console dentro do container do backend
	@$(MAKE) exec service="$(rails_container)" cmd="bash"

# Rails commands in Docker container

.PHONY: console
console: ## Abre o rails console dentro do container do backend
	@$(MAKE) exec service="$(rails_container)" cmd="rails c"

.PHONY: migrate
migrate: ## Roda as migrações do banco (rails db:migrate)
	@$(MAKE) exec service="$(rails_container)" cmd="rails db:migrate"

.PHONY: seed
seed: ## Roda o seed do banco (rails db:seed)
	@$(MAKE) exec service="$(rails_container)" cmd="rails db:seed"

.PHONY: setup
setup: ## Instala/prepara o banco de dados (rails db:setup)
	@$(MAKE) exec service="$(rails_container)" cmd="rails db:setup"