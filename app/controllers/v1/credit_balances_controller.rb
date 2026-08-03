class V1::CreditBalancesController < ApplicationController
  before_action :set_wallet, only: [:index, :create]
  before_action :set_credit_balance, only: [:show, :update, :destroy, :invoice, :pay_invoice]

  def index
    @credit_balances = @wallet.credit_balances
    @credit_balances = search_bar(@credit_balances, params[:terms], ["credit_balances.name"])
    @credit_balances = paginate(@credit_balances, params[:page], params[:per_page])
    render json: @credit_balances, status: :ok
  end

  def show
    render json: { data: @credit_balance }, status: :ok
  end

  def create
    @credit_balance = @wallet.credit_balances.new(credit_balance_params)

    return render json: { message: @credit_balance.errors.full_messages.join(', ') }, status: :unprocessable_content unless @credit_balance.save

    render json: { data: @credit_balance }, status: :created
  end

  def update
    return render json: { message: @credit_balance.errors.full_messages.join(', ') }, status: :unprocessable_content unless @credit_balance.update(credit_balance_params)

    render json: { data: @credit_balance }, status: :ok
  end

  def destroy
    return render json: { message: @credit_balance.errors.full_messages.join(', ') }, status: :unprocessable_content unless @credit_balance.discard

    render json: { message: 'Saldo de crédito removido com sucesso!' }, status: :ok
  end

  def invoice
    render json: { data: resolved_invoice }, status: :ok
  end

  def pay_invoice
    account = Account.accessible_by(@current_user).find_by(id: params[:account_id])
    return render json: { message: 'Conta pagadora não encontrada.' }, status: :unprocessable_content if account.nil?

    invoice = resolved_invoice
    return render json: { message: 'Não há fatura em aberto para pagar.' }, status: :unprocessable_content if invoice[:amount] <= 0

    value = params[:value].presence&.to_i || invoice[:remaining]
    return render json: { message: 'Informe um valor de pagamento maior que zero.' }, status: :unprocessable_content if value <= 0

    payment = Transaction.new(
      description: params[:description].presence || "Fatura #{@credit_balance.name}",
      value: value,
      kind: "withdraw",
      transaction_date: invoice[:due_date],
      settled_at: params[:settled_at].presence || Time.current,
      source: account,
      paid_credit_balance: @credit_balance,
      user: @current_user
    )

    return render json: { message: payment.errors.full_messages.join(', ') }, status: :unprocessable_content unless payment.save

    render json: { data: payment }, status: :created
  end

  private

  def resolved_invoice
    year, month = month_reference
    return @credit_balance.invoice_for_month(year, month) if year && month

    @credit_balance.current_invoice(invoice_reference)
  end

  def month_reference
    if params[:reference].present? && (match = params[:reference].match(/\A(\d{4})-(\d{1,2})\z/))
      return [match[1].to_i, match[2].to_i]
    end

    return [params[:year].to_i, params[:month].to_i] if params[:year].present? && params[:month].present?

    nil
  end

  def invoice_reference
    params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
  rescue ArgumentError
    Time.zone.today
  end

  def set_wallet
    wallet_id = params[:wallet_id] || params.dig(:credit_balance, :wallet_id)
    @wallet = Wallet.accessible_by(@current_user).find_by(id: wallet_id)
    render json: { message: 'Carteira não encontrada.' }, status: :unprocessable_content if @wallet.nil?
  end

  def set_credit_balance
    @credit_balance = CreditBalance.accessible_by(@current_user).find_by(id: params[:id])
    render json: { message: 'Saldo de crédito não encontrado.' }, status: :unprocessable_content if @credit_balance.nil?
  end

  def credit_balance_params
    params.require(:credit_balance).permit(:name, :credit_limit, :closing_day, :due_day)
  end
end
