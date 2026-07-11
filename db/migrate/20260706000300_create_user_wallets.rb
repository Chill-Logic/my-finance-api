class CreateUserWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :user_wallets, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :wallet, null: false, type: :uuid, foreign_key: true
      t.boolean :accepted, null: false, default: false

      t.datetime :discarded_at
      t.timestamps
    end

    add_index :user_wallets, [:user_id, :wallet_id, :discarded_at], unique: true
  end
end
