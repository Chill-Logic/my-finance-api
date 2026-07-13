class CreateCreditCards < ActiveRecord::Migration[8.1]
  def change
    create_table :credit_cards, id: :uuid do |t|
      t.string :name
      t.string :last_digits
      t.references :credit_balance, null: false, type: :uuid, foreign_key: true

      t.datetime :discarded_at
      t.timestamps
    end
  end
end
