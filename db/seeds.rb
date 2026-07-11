# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if User.all.empty?
  puts "Criando usuários padrão"
  gabriel = User.create!(name: "Gabriel", email: "gbrparanhos@gmail.com", password: "123123")
  jhon = User.create!(name: "Jhon", email: "jhonathancarv.s@gmail.com", password: "123123")

  puts "Criando carteira compartilhada com convite pendente"
  shared_wallet = Wallet.create!(name: "Carteira Compartilhada", owner: gabriel)
  UserWallet.create!(user: jhon, wallet: shared_wallet)

  puts "Criando transações teste"
  main_wallet = gabriel.main_user_wallet.wallet
  Transaction.create!(description: "Salário", value: 500_000, kind: :deposit, wallet: main_wallet, user: gabriel, transaction_date: Date.current.beginning_of_month)
  Transaction.create!(description: "Mercado", value: 35_000, kind: :withdraw, wallet: main_wallet, user: gabriel, transaction_date: Date.current)
end
