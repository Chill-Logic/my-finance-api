class CreditCard < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :accessible_by, ->(user) { where(credit_balance_id: CreditBalance.accessible_by(user).select("credit_balances.id")) }

  belongs_to :credit_balance
  has_many :transactions

  validates :name, presence: true
end
