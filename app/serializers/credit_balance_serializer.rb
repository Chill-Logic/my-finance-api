class CreditBalanceSerializer < ActiveModel::Serializer
  attributes(CreditBalance.column_names + [:used, :available, :current_invoice])

  def used
    object.used
  end

  def available
    object.available
  end

  def current_invoice
    object.current_invoice
  end
end
