class BackfillTransactionsSource < ActiveRecord::Migration[8.1]
  # Realoca as transações legadas (que pendiam direto da wallet) para uma conta
  # padrão por carteira e as marca como já efetivadas, preservando os saldos.
  # Idempotente: só toca em transações sem source.
  def up
    execute(<<~SQL)
      INSERT INTO accounts (id, name, kind, initial_balance, wallet_id, created_at, updated_at)
      SELECT gen_random_uuid(), 'Conta principal', 'cash', 0, w.id, now(), now()
      FROM wallets w
      WHERE w.discarded_at IS NULL
        AND EXISTS (SELECT 1 FROM transactions t WHERE t.wallet_id = w.id AND t.source_id IS NULL)
        AND NOT EXISTS (
          SELECT 1 FROM accounts a
          WHERE a.wallet_id = w.id AND a.name = 'Conta principal' AND a.discarded_at IS NULL
        );
    SQL

    execute(<<~SQL)
      UPDATE transactions t
      SET source_type = 'Account',
          source_id   = a.id,
          settled_at  = COALESCE(t.settled_at, t.transaction_date)
      FROM accounts a
      WHERE a.wallet_id = t.wallet_id
        AND a.name = 'Conta principal'
        AND a.discarded_at IS NULL
        AND t.source_id IS NULL;
    SQL

    change_column_null :transactions, :source_type, false
    change_column_null :transactions, :source_id, false
  end

  def down
    change_column_null :transactions, :source_type, true
    change_column_null :transactions, :source_id, true
  end
end
