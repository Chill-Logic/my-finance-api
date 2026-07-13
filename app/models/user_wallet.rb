class UserWallet < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :accepted, -> { where(accepted: true) }
  scope :pending, -> { where(accepted: false) }

  belongs_to :user
  belongs_to :wallet

  validates :user_id, uniqueness: { scope: :wallet_id, conditions: -> { kept } }

  after_discard :reset_main_reference_for_users

  private

  def reset_main_reference_for_users
    User.where(main_user_wallet_id: id).find_each(&:reset_main_user_wallet!)
  end
end
