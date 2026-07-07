require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MyFinanceApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    
    config.i18n.default_locale = :'pt-BR'
    config.time_zone = 'Brasilia'
    config.active_record.default_timezone = :utc

    # Dump do schema.rb sempre relativo ao schema do ambiente (multi-schema via POSTGRES_SCHEMA),
    # para as tabelas saírem sem qualificação de schema no dump
    config.active_record.dump_schemas = ENV.fetch("POSTGRES_SCHEMA") { "public" }

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid # PKs em uuid (paridade com os clientes e o banco legado)
      g.test_framework :rspec,           # Define o RSpec como framework de testes padrão
        view_specs: false,               # Gera testes para views
        helper_specs: false,             # Gera testes para helpers
        routing_specs: false,            # Gera testes para rotas
        controller_specs: false,         # Gera testes para controllers
        request_specs: true              # Gera testes para requisições (request specs)
    end
  end
end
