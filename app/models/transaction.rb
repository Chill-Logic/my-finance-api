class Transaction < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  # Casteia antes de filtrar: valor não-parseável (ex: "null" vindo do front)
  # viraria `transaction_date <= NULL` e zeraria o resultado.
  scope :from_date, ->(date) {
    date = ActiveModel::Type::Date.new.cast(date)
    where(transaction_date: date..) if date
  }
  scope :to_date, ->(date) {
    date = ActiveModel::Type::Date.new.cast(date)
    where(transaction_date: ..date) if date
  }

  enum :kind, ["deposit", "withdraw"].index_with(&:itself)

  belongs_to :wallet
  belongs_to :user

  validates :description, presence: true
  validates :value, presence: true, numericality: { only_integer: true }
  validates :kind, presence: true
  validates :transaction_date, presence: true

  def self.balance
    deposit.sum(:value) - withdraw.sum(:value)
  end
end
