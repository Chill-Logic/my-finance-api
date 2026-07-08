class Wallet < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :accessible_by, ->(user) { joins(:user_wallets).where(user_wallets: { user_id: user.id, accepted: true }) }

  dependent_discard :user_wallets
  dependent_discard :transactions

  belongs_to :owner, class_name: "User"
  has_many :user_wallets
  has_many :users, through: :user_wallets
  has_many :transactions

  validates :name, presence: true

  after_create :create_owner_user_wallet

  def total
    transactions.balance
  end

  private

  def create_owner_user_wallet
    user_wallets.create!(user: owner, accepted: true)
  end
end
