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

  def cycle_for_month(year, month)
    ref = Date.new(year.to_i, month.to_i, 1)
    start_ref, end_ref = self.due_day < self.closing_day ? [ref.prev_month, ref] : [ref, ref.next_month]
    cycle_start = self.closing_on(start_ref.year, start_ref.month) + 1.day
    cycle_end = self.closing_on(end_ref.year, end_ref.month)
    cycle_start.in_time_zone.beginning_of_day..cycle_end.in_time_zone.end_of_day
  end

  def billed_cycle_for_month(year, month)
    ref = Date.new(year.to_i, month.to_i, 1).prev_month
    self.cycle_for_month(ref.year, ref.month)
  end

  def cycle_range(reference = Time.zone.today)
    reference = reference.to_date
    closing_this = self.closing_on(reference.year, reference.month)

    if reference <= closing_this
      cycle_end = closing_this
      prev = reference.prev_month
      cycle_start = self.closing_on(prev.year, prev.month) + 1.day
    else
      nxt = reference.next_month
      cycle_end = self.closing_on(nxt.year, nxt.month)
      cycle_start = closing_this + 1.day
    end

    cycle_start.in_time_zone.beginning_of_day..cycle_end.in_time_zone.end_of_day
  end

  def used
    charges = self.transactions.not_draft
    paid = self.invoice_payments.settled.sum(:value)
    charges.withdraw.sum(:value) - charges.deposit.sum(:value) - paid
  end

  def available
    self.credit_limit.to_i - self.used
  end

  def current_invoice(reference = Time.zone.today)
    ref = reference.to_date
    fallback = self.invoice_for_range(self.cycle_for_month(ref.year, ref.month))
    earliest = self.transactions.not_draft.minimum(:transaction_date)
    return fallback if earliest.nil?

    month = earliest.to_date.beginning_of_month
    last = ref.beginning_of_month
    while month <= last
      invoice = self.invoice_for_month(month.year, month.month)
      return invoice if invoice[:amount].positive? && invoice[:remaining].positive?

      month = month.next_month
    end

    fallback
  end

  def invoice_on(reference = Time.zone.today)
    self.invoice_for_range(self.cycle_range(reference))
  end

  def invoice_for_month(year, month)
    self.invoice_for_range(self.billed_cycle_for_month(year, month))
  end

  def paid_amount(due_date)
    self.invoice_payments.settled.where(transaction_date: due_date.all_day).sum(:value)
  end

  private

  def used_in(range)
    scope = self.transactions.not_draft.where(transaction_date: range)
    scope.withdraw.sum(:value) - scope.deposit.sum(:value)
  end

  def invoice_for_range(range)
    due = self.due_on(range.end.to_date)
    amount = self.used_in(range)
    paid = self.paid_amount(due)
    remaining = [amount - paid, 0].max

    {
      amount: amount,
      paid_amount: paid,
      remaining: remaining,
      cycle_start: range.begin,
      cycle_end: range.end,
      due_date: due,
      paid: amount.positive? && remaining.zero?
    }
  end

  def closing_on(year, month)
    Date.new(year, month, [self.closing_day, Time.days_in_month(month, year)].min)
  end

  def due_on(closing_date)
    candidate = self.clamp_day(closing_date.year, closing_date.month)
    return candidate if candidate > closing_date

    nxt = closing_date.next_month
    self.clamp_day(nxt.year, nxt.month)
  end

  def clamp_day(year, month)
    Date.new(year, month, [self.due_day, Time.days_in_month(month, year)].min)
  end
end
