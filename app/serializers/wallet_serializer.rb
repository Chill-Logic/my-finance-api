class WalletSerializer < ActiveModel::Serializer
  attributes(Wallet.column_names + [:total])

  def total
    object.total
  end
end
