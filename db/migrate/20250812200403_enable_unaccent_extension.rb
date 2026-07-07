class EnableUnaccentExtension < ActiveRecord::Migration[8.1]
  # SCHEMA public explícito: com multi-schema por ambiente, o CREATE EXTENSION
  # instalaria a extensão no primeiro schema do search_path (o schema do
  # ambiente), e ela sumiria junto num DROP SCHEMA ... CASCADE.
  def up
    execute "CREATE EXTENSION IF NOT EXISTS unaccent SCHEMA public"
  end

  def down
    execute "DROP EXTENSION IF EXISTS unaccent"
  end
end
