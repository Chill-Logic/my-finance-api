class UserWalletSerializer < ActiveModel::Serializer
  attributes(UserWallet.column_names + [:wallet_name, :owner_name])

  def wallet_name
    object.wallet.name
  end

  def owner_name
    object.wallet.owner.name
  end
end
