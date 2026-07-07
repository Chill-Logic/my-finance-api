class TransactionSerializer < ActiveModel::Serializer
  include TranslatableEnums

  attributes([:id, :description, :value, :kind, :transaction_date, :wallet_id, :user_id, :user_name, :discarded_at, :created_at, :updated_at] + translatable_enums(:kind))

  def user_name
    object.user.name
  end
end
