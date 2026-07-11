class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.string :description
      t.integer :value
      t.string :kind
      t.datetime :transaction_date
      t.references :wallet, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true

      t.datetime :discarded_at
      t.timestamps
    end
  end
end
