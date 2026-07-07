# Com multi-schema por ambiente (POSTGRES_SCHEMA no database.yml), o dump do
# schema.rb não pode fixar o nome do schema do ambiente que o gerou (ex.:
# `create_schema "my_finance_dev"`), senão o load em outro ambiente cria um
# schema errado. As tabelas continuam sendo dumpadas sem qualificação e a
# criação do schema correto fica por conta da task db:ensure_schema.
module SchemaDumperWithoutCreateSchema
  private

  def schemas(stream); end
end

ActiveSupport.on_load(:active_record_postgresqladapter) do
  ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.prepend(SchemaDumperWithoutCreateSchema)
end
