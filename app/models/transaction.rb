class Transaction < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :from_date, ->(date, timezone = nil) {
    date = ActiveModel::Type::Date.new.cast(date)
    where(transaction_date: date.in_time_zone(Time.find_zone(timezone) || Time.zone)..) if date
  }
  scope :to_date, ->(date, timezone = nil) {
    date = ActiveModel::Type::Date.new.cast(date)
    where(transaction_date: ..date.in_time_zone(Time.find_zone(timezone) || Time.zone).end_of_day) if date
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
