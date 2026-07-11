class UserSerializer < ActiveModel::Serializer
  attributes [:id, :email, :name, :main_user_wallet_id, :created_at, :updated_at]
end
