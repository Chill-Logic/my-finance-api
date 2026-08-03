class TransactionSerializer < ActiveModel::Serializer
  include TranslatableEnums

  attributes(Transaction.column_names + translatable_enums(:kind) + [:user_name, :settled])

  def user_name
    object.user.name
  end

  def settled
    object.settled?
  end
end
