class AccountSerializer < ActiveModel::Serializer
  include TranslatableEnums

  attributes(Account.column_names + translatable_enums(:kind) + [:balance])

  def balance
    object.balance
  end
end
