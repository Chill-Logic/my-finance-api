# Migração in-place do banco legado (NestJS + MikroORM) para a estrutura Rails,
# aproveitando as tabelas existentes (sem copiar dados). Roda no schema do
# ambiente atual (POSTGRES_SCHEMA), então o mesmo comando serve para dev e prod:
#
#   bin/rails nest:migrate   # transacional: qualquer erro reverte tudo
#
# O que a task faz:
#   - users.password -> users.encrypted_password (hashes bcrypt continuam válidos)
#     + colunas do Devise recoverable (reset_password_token/sent_at)
#   - timestamptz -> timestamp em UTC; transaction_date (meia-noite de SP) -> date
#   - alinha limits/not null/check constraints com o db/schema.rb
#   - troca índices/FKs do MikroORM pelos equivalentes com nomes Rails, para o
#     dump do schema.rb (automático em development) não divergir do commitado
#   - cria versions (PaperTrail), schema_migrations (estampada) e ar_internal_metadata
#   - remove mikro_orm_migrations
namespace :nest do
  desc "Converte in-place o schema atual da estrutura Nest (MikroORM) para a estrutura Rails"
  task migrate: :environment do
    connection = ActiveRecord::Base.connection
    schema = connection.schema_search_path.split(",").first.strip.delete('"')

    abort "O schema #{schema} não tem a estrutura Nest (users.password não encontrado). Nada a migrar." unless nest_column?(connection, schema, "users", "password")
    abort "O schema #{schema} já contém a estrutura Rails (schema_migrations presente)." if nest_table?(connection, schema, "schema_migrations")

    puts "Convertendo o schema #{schema} da estrutura Nest para Rails..."

    ActiveRecord::Base.transaction do
      convert_users(connection)
      convert_wallets(connection)
      convert_user_wallets(connection)
      convert_transactions(connection)
      replace_foreign_keys(connection)
      create_versions_table(connection)
      ensure_unaccent_extension(connection)
      stamp_rails_migrations(connection)
      connection.drop_table(:mikro_orm_migrations, if_exists: true)
      validate_structure!(connection, schema)
    end

    puts "Conversão concluída! Rode a aplicação e valide; db:migrate já está estampado."
  end

  def nest_table?(connection, schema, table)
    connection.select_value(<<~SQL, "SQL", [schema, table]).present?
      SELECT 1 FROM information_schema.tables WHERE table_schema = $1 AND table_name = $2
    SQL
  end

  def nest_column?(connection, schema, table, column)
    connection.select_value(<<~SQL, "SQL", [schema, table, column]).present?
      SELECT 1 FROM information_schema.columns WHERE table_schema = $1 AND table_name = $2 AND column_name = $3
    SQL
  end

  def convert_users(connection)
    puts "Convertendo users..."
    connection.execute(<<~SQL)
      ALTER TABLE users RENAME COLUMN password TO encrypted_password;
      ALTER TABLE users
        ALTER COLUMN email TYPE varchar,
        ALTER COLUMN email SET DEFAULT '',
        ALTER COLUMN encrypted_password TYPE varchar,
        ALTER COLUMN encrypted_password SET DEFAULT '',
        ALTER COLUMN name TYPE varchar,
        ALTER COLUMN name DROP NOT NULL,
        ALTER COLUMN created_at TYPE timestamp(6) USING created_at AT TIME ZONE 'UTC',
        ALTER COLUMN updated_at TYPE timestamp(6) USING updated_at AT TIME ZONE 'UTC',
        ALTER COLUMN discarded_at TYPE timestamp(6) USING discarded_at AT TIME ZONE 'UTC',
        ADD COLUMN reset_password_token varchar,
        ADD COLUMN reset_password_sent_at timestamp(6);
      ALTER TABLE users DROP CONSTRAINT users_email_unique;
    SQL

    connection.add_index :users, [:email, :discarded_at], unique: true
    connection.add_index :users, :reset_password_token, unique: true
    connection.add_index :users, :main_user_wallet_id
  end

  def convert_wallets(connection)
    puts "Convertendo wallets..."
    connection.execute(<<~SQL)
      ALTER TABLE wallets
        ALTER COLUMN name TYPE varchar,
        ALTER COLUMN name DROP NOT NULL,
        ALTER COLUMN created_at TYPE timestamp(6) USING created_at AT TIME ZONE 'UTC',
        ALTER COLUMN updated_at TYPE timestamp(6) USING updated_at AT TIME ZONE 'UTC',
        ALTER COLUMN discarded_at TYPE timestamp(6) USING discarded_at AT TIME ZONE 'UTC';
    SQL

    connection.add_index :wallets, :owner_id
  end

  def convert_user_wallets(connection)
    puts "Convertendo user_wallets..."
    connection.execute(<<~SQL)
      ALTER TABLE user_wallets
        ALTER COLUMN created_at TYPE timestamp(6) USING created_at AT TIME ZONE 'UTC',
        ALTER COLUMN updated_at TYPE timestamp(6) USING updated_at AT TIME ZONE 'UTC',
        ALTER COLUMN discarded_at TYPE timestamp(6) USING discarded_at AT TIME ZONE 'UTC';
    SQL

    connection.add_index :user_wallets, :user_id
    connection.add_index :user_wallets, :wallet_id
    connection.add_index :user_wallets, [:user_id, :wallet_id, :discarded_at], unique: true
  end

  def convert_transactions(connection)
    puts "Convertendo transactions..."
    # transaction_date era timestamptz normalizado à meia-noite de São Paulo
    # (03:00 UTC); a data correta é a do fuso de SP, não a de UTC.
    connection.execute(<<~SQL)
      ALTER TABLE transactions
        ALTER COLUMN description TYPE varchar,
        ALTER COLUMN description DROP NOT NULL,
        ALTER COLUMN value DROP NOT NULL,
        ALTER COLUMN kind TYPE varchar,
        ALTER COLUMN kind DROP NOT NULL,
        ALTER COLUMN transaction_date TYPE date USING (transaction_date AT TIME ZONE 'America/Sao_Paulo')::date,
        ALTER COLUMN transaction_date DROP NOT NULL,
        ALTER COLUMN created_at TYPE timestamp(6) USING created_at AT TIME ZONE 'UTC',
        ALTER COLUMN updated_at TYPE timestamp(6) USING updated_at AT TIME ZONE 'UTC',
        ALTER COLUMN discarded_at TYPE timestamp(6) USING discarded_at AT TIME ZONE 'UTC';
      ALTER TABLE transactions DROP CONSTRAINT transactions_kind_check;
    SQL

    connection.add_index :transactions, :wallet_id
    connection.add_index :transactions, :user_id
  end

  def replace_foreign_keys(connection)
    puts "Trocando as foreign keys pelos nomes Rails..."
    connection.execute(<<~SQL)
      ALTER TABLE wallets DROP CONSTRAINT wallets_owner_id_foreign;
      ALTER TABLE users DROP CONSTRAINT users_main_user_wallet_id_foreign;
      ALTER TABLE user_wallets DROP CONSTRAINT user_wallets_user_id_foreign;
      ALTER TABLE user_wallets DROP CONSTRAINT user_wallets_wallet_id_foreign;
      ALTER TABLE transactions DROP CONSTRAINT transactions_wallet_id_foreign;
      ALTER TABLE transactions DROP CONSTRAINT transactions_user_id_foreign;
    SQL

    connection.add_foreign_key :wallets, :users, column: :owner_id
    connection.add_foreign_key :users, :user_wallets, column: :main_user_wallet_id
    connection.add_foreign_key :user_wallets, :users
    connection.add_foreign_key :user_wallets, :wallets
    connection.add_foreign_key :transactions, :wallets
    connection.add_foreign_key :transactions, :users
  end

  def create_versions_table(connection)
    puts "Criando a tabela versions (PaperTrail)..."
    connection.create_table :versions, id: :uuid do |t|
      t.string :item_type, null: false
      t.uuid :item_id, null: false
      t.string :event, null: false
      t.string :whodunnit
      t.text :object, limit: 1_073_741_823
      t.jsonb :object_changes
      t.datetime :created_at
    end
    connection.add_index :versions, [:item_type, :item_id]
  end

  def ensure_unaccent_extension(connection)
    # A migration da extensão será estampada sem rodar; garante que ela exista.
    connection.execute("CREATE EXTENSION IF NOT EXISTS unaccent SCHEMA public")
  end

  def stamp_rails_migrations(connection)
    puts "Criando e estampando a schema_migrations..."
    pool = ActiveRecord::Base.connection_pool
    pool.schema_migration.create_table
    pool.migration_context.migrations.each { |migration| pool.schema_migration.create_version(migration.version) }
    pool.internal_metadata.create_table_and_set_flags(Rails.env)
  end

  def validate_structure!(connection, schema)
    expected_types = {
      %w[users encrypted_password] => "character varying",
      %w[users reset_password_token] => "character varying",
      %w[users created_at] => "timestamp without time zone",
      %w[transactions transaction_date] => "date",
      %w[transactions kind] => "character varying",
      %w[versions item_id] => "uuid",
    }

    expected_types.each do |(table, column), expected|
      actual = connection.select_value(<<~SQL, "SQL", [schema, table, column])
        SELECT data_type FROM information_schema.columns WHERE table_schema = $1 AND table_name = $2 AND column_name = $3
      SQL
      raise "Coluna #{table}.#{column} deveria ser #{expected}, mas é #{actual.inspect}" unless actual == expected
    end

    pending = ActiveRecord::Base.connection_pool.migration_context.open.pending_migrations
    raise "Migrations pendentes após a estampagem: #{pending.map(&:version).join(', ')}" if pending.any?

    puts "Estrutura validada; nenhuma migration pendente."
  end
end
