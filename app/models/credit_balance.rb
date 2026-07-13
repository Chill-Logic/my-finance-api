class CreditBalance < ApplicationRecord
  include Discard::Model

  default_scope -> { kept }

  scope :accessible_by, ->(user) { where(wallet_id: Wallet.accessible_by(user).select("wallets.id")) }

  dependent_discard :transactions
  dependent_discard :credit_cards

  belongs_to :wallet
  has_many :transactions, as: :source
  has_many :credit_cards
  has_many :invoice_payments, class_name: "Transaction", foreign_key: :paid_credit_balance_id

  validates :name, presence: true
  validates :credit_limit, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :closing_day, :due_day, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }

  def cycle_range(reference = Time.zone.today)
    reference = reference.to_date
    closing_this = closing_on(reference.year, reference.month)

    if reference <= closing_this
      cycle_end = closing_this
      prev = reference.prev_month
      cycle_start = closing_on(prev.year, prev.month) + 1.day
    else
      nxt = reference.next_month
      cycle_end = closing_on(nxt.year, nxt.month)
      cycle_start = closing_this + 1.day
    end

    cycle_start.in_time_zone.beginning_of_day..cycle_end.in_time_zone.end_of_day
  end

  def used(reference = Time.zone.today)
    scope = transactions.not_draft.where(transaction_date: cycle_range(reference))
    scope.withdraw.sum(:value) - scope.deposit.sum(:value)
  end

  def available(reference = Time.zone.today)
    credit_limit.to_i - used(reference)
  end

  def current_invoice(reference = Time.zone.today)
    range = cycle_range(reference)
    due = due_on(range.end.to_date)

    {
      amount: used(reference),
      cycle_start: range.begin,
      cycle_end: range.end,
      due_date: due,
      paid: invoice_paid?(due)
    }
  end

  def invoice_paid?(due_date)
    invoice_payments.settled.where(transaction_date: due_date.all_day).exists?
  end

  private

  def closing_on(year, month)
    Date.new(year, month, [closing_day, Time.days_in_month(month, year)].min)
  end

  def due_on(closing_date)
    candidate = clamp_day(closing_date.year, closing_date.month)
    return candidate if candidate >= closing_date

    nxt = closing_date.next_month
    clamp_day(nxt.year, nxt.month)
  end

  def clamp_day(year, month)
    Date.new(year, month, [due_day, Time.days_in_month(month, year)].min)
  end
end
