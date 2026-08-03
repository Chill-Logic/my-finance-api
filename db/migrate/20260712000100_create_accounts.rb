class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name
      t.string :kind
      t.integer :initial_balance, null: false, default: 0
      t.references :wallet, null: false, type: :uuid, foreign_key: true

      t.datetime :discarded_at
      t.timestamps
    end
  end
end
