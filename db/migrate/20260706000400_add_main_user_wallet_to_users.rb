class AddMainUserWalletToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :main_user_wallet, type: :uuid, foreign_key: { to_table: :user_wallets }
  end
end
