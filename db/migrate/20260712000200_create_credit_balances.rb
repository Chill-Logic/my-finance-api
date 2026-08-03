class CreateCreditBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_balances, id: :uuid do |t|
      t.string :name
      t.integer :credit_limit
      t.integer :closing_day
      t.integer :due_day
      t.references :wallet, null: false, type: :uuid, foreign_key: true

      t.datetime :discarded_at
      t.timestamps
    end
  end
end
