Rswag::Ui.configure do |c|
  c.openapi_endpoint '/api-docs/v1/auth.yaml',         'Auth, Core & User'
  c.openapi_endpoint '/api-docs/v1/wallets.yaml',      'Wallets'
  c.openapi_endpoint '/api-docs/v1/transactions.yaml', 'Transactions'
  c.openapi_endpoint '/api-docs/v1/user_wallets.yaml', 'User Wallets — Convites'

  # c.config_object[:supportedSubmitMethods] = [] if Rails.env.production?
end
