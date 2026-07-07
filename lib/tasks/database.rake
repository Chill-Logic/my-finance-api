namespace :db do
  desc "Garante que o schema do Postgres (POSTGRES_SCHEMA) existe antes de criar as tabelas"
  task ensure_schema: :environment do
    connection = ActiveRecord::Base.connection
    schema = connection.schema_search_path.split(",").first.strip.delete('"')
    connection.execute("CREATE SCHEMA IF NOT EXISTS #{connection.quote_table_name(schema)}")
  end
end

%w[db:migrate db:schema:load].each do |task|
  Rake::Task[task].enhance(["db:ensure_schema"])
end
