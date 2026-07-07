Rswag::Api.configure do |c|
  # Diretório onde os arquivos swagger.yaml/swagger.json ficam armazenados.
  # Por padrão serve tudo que estiver dentro de public/api-docs.
  c.openapi_root = Rails.root.join('public/api-docs').to_s
end
