class Transaction < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :for_month, ->(year, month) {
    ref = Time.zone.local(year.to_i, month.to_i, 1)
    where(transaction_date: ref.beginning_of_month..ref.end_of_month)
  }
  scope :settled, -> { where.not(settled_at: nil) }
  scope :pending, -> { where(settled_at: nil) }
  scope :not_draft, -> { where(draft: false) }

  enum :kind, ["deposit", "withdraw"].index_with(&:itself)

  belongs_to :source, polymorphic: true
  belongs_to :wallet
  belongs_to :user
  belongs_to :credit_card, optional: true
  belongs_to :paid_credit_balance, class_name: "CreditBalance", optional: true

  before_validation :assign_wallet_from_source

  validates :description, presence: true
  validates :value, presence: true, numericality: { only_integer: true }
  validates :kind, presence: true
  validates :transaction_date, presence: true
  validate :credit_card_matches_source

  def self.balance(mode = :effective)
    scope = not_draft
    scope = scope.settled if mode == :effective
    scope.deposit.sum(:value) - scope.withdraw.sum(:value)
  end

  def settled?
    settled_at.present?
  end

  private

  def assign_wallet_from_source
    self.wallet_id = source.wallet_id if source.present?
  end

  def credit_card_matches_source
    return if credit_card_id.blank?

    unless source.is_a?(CreditBalance) && credit_card&.credit_balance_id == source_id
      errors.add(:credit_card, :invalid)
    end
  end
end
