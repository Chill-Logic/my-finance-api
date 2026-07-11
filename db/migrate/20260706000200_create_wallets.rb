class CreateWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :wallets, id: :uuid do |t|
      t.string :name
      t.references :owner, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.datetime :discarded_at
      t.timestamps
    end
  end
end
