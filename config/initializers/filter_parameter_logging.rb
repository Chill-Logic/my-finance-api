# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.

# Credenciais e segredos: filtrados em todos os ambientes (o match é por
# substring — :token cobre reset_password_token, :_key cobre api_key etc.)
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
]

# LGPD: em produção filtra também dados pessoais (identificação do titular)
# e financeiros (descrição/valor de transações revelam hábitos de consumo).
# Em development/test ficam visíveis para facilitar o debug.
if Rails.env.production?
  Rails.application.config.filter_parameters += [
    :description, :value, :cpf, :phone, :birth
  ]
end
