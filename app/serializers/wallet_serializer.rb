class WalletSerializer < ActiveModel::Serializer
  attributes(Wallet.column_names + [:total, :total_projected])

  def total
    object.total(:effective)
  end

  def total_projected
    object.total(:projected)
  end
end
