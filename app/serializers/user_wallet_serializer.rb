class UserWalletSerializer < ActiveModel::Serializer
  attributes [:id, :user_id, :wallet_id, :accepted, :wallet_name, :owner_name, :discarded_at, :created_at, :updated_at]

  def wallet_name
    object.wallet.name
  end

  def owner_name
    object.wallet.owner.name
  end
end
