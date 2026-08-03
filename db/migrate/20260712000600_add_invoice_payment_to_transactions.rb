class AddInvoicePaymentToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :paid_credit_balance, type: :uuid, foreign_key: { to_table: :credit_balances }, index: true
  end
end
