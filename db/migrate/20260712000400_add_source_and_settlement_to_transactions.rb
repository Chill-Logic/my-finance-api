class AddSourceAndSettlementToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :source, polymorphic: true, type: :uuid, index: true
    add_reference :transactions, :credit_card, type: :uuid, foreign_key: true, index: true

    add_column :transactions, :settled_at, :datetime
    add_column :transactions, :draft, :boolean, null: false, default: false

    add_index :transactions, [:wallet_id, :transaction_date]
  end
end
