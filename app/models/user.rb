class User < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  devise :database_authenticatable, :registerable, :recoverable, :validatable

  dependent_discard :user_wallets

  belongs_to :main_user_wallet, class_name: "UserWallet", optional: true
  has_many :user_wallets
  has_many :wallets, through: :user_wallets
  has_many :owned_wallets, class_name: "Wallet", foreign_key: :owner_id
  has_many :transactions

  validates :name, presence: true

  after_create :create_default_wallet

  after_discard do
    self.update_columns(email: "#{DateTime.now.strftime("%Y%m%d%H%M")}#{self.email}")
  end

  def reset_main_user_wallet!
    fallback = user_wallets.accepted.joins(:wallet).where(wallets: { owner_id: id }).order("wallets.created_at").first ||
               user_wallets.accepted.order(:created_at).first

    update_column(:main_user_wallet_id, fallback&.id)
  end

  private

  def create_default_wallet
    wallet = Wallet.create!(name: "Minha Carteira", owner: self)
    update_column(:main_user_wallet_id, wallet.user_wallets.find_by(user: self).id)
  end
end
