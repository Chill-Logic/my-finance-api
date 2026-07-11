class TransactionSerializer < ActiveModel::Serializer
  include TranslatableEnums

  attributes(Transaction.column_names + translatable_enums(:kind) + [:user_name])

  def user_name
    object.user.name
  end
end
