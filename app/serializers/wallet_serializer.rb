class WalletSerializer < ActiveModel::Serializer
  attributes [:id, :name, :owner_id, :total, :discarded_at, :created_at, :updated_at]

  def total
    object.total
  end
end
