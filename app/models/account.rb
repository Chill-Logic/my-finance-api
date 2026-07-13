class Account < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :accessible_by, ->(user) { where(wallet_id: Wallet.accessible_by(user).select("wallets.id")) }

  dependent_discard :transactions

  enum :kind, ["checking", "savings", "cash"].index_with(&:itself)

  belongs_to :wallet
  has_many :transactions, as: :source

  validates :name, presence: true

  def balance(mode = :effective)
    initial_balance.to_i + transactions.balance(mode)
  end
end
