class CreditCardSerializer < ActiveModel::Serializer
  attributes(CreditCard.column_names)
end
