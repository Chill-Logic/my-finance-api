class UserWallet < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :accepted, -> { where(accepted: true) }
  scope :pending, -> { where(accepted: false) }

  belongs_to :user
  belongs_to :wallet

  validates :user_id, uniqueness: { scope: :wallet_id, conditions: -> { kept } }
end
