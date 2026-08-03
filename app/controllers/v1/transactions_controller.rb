class V1::TransactionsController < ApplicationController
  before_action :set_wallet, only: [:index]
  before_action :set_source, only: [:create]
  before_action :set_transaction, only: [:show, :update, :destroy, :settle, :unsettle]

  def index
    year, month = resolve_month
    scope = filter_by_source(@wallet.transactions)
    scope = search_bar(scope, params[:terms], ["transactions.description"])

    render json: {
      accounts: transaction_group(scope.where(source_type: "Account").for_month(year, month)),
      credits: transaction_group(credit_cycle_scope(scope, year, month))
    }, status: :ok
  end

  def show
    render json: { data: @transaction }, status: :ok
  end

  def settle
    return render json: { message: @transaction.errors.full_messages.join(', ') }, status: :unprocessable_content unless @transaction.update(settled_at: params[:settled_at].presence || Time.current)

    render json: { data: @transaction }, status: :ok
  end

  def unsettle
    return render json: { message: @transaction.errors.full_messages.join(', ') }, status: :unprocessable_content unless @transaction.update(settled_at: nil)

    render json: { data: @transaction }, status: :ok
  end

  def create
    @transaction = Transaction.new(transaction_params.merge(user: @current_user, source: @source))

    return render json: { message: @transaction.errors.full_messages.join(', ') }, status: :unprocessable_content unless @transaction.save

    render json: { data: @transaction }, status: :created
  end

  def update
    return render json: { message: @transaction.errors.full_messages.join(', ') }, status: :unprocessable_content unless @transaction.update(transaction_params)

    render json: { data: @transaction }, status: :ok
  end

  def destroy
    return render json: { message: @transaction.errors.full_messages.join(', ') }, status: :unprocessable_content unless @transaction.discard

    render json: { message: 'Transação removida com sucesso!' }, status: :ok
  end

  private

  def set_wallet
    wallet_id = params[:wallet_id] || params.dig(:transaction, :wallet_id)
    @wallet = Wallet.accessible_by(@current_user).find_by(id: wallet_id)
    render json: { message: 'Carteira não encontrada.' }, status: :unprocessable_content if @wallet.nil?
  end

  def resolve_month
    if params[:reference].present? && (match = params[:reference].match(/\A(\d{4})-(\d{1,2})\z/))
      return [match[1].to_i, match[2].to_i]
    end

    year = params[:year].presence&.to_i || Time.zone.today.year
    month = params[:month].presence&.to_i || Time.zone.today.month
    [year, month]
  end

  def filter_by_source(scope)
    return scope unless params[:source_type].present? && params[:source_id].present?

    scope.where(source_type: params[:source_type], source_id: params[:source_id])
  end

  def credit_cycle_scope(scope, year, month)
    credit = scope.where(source_type: "CreditBalance")
    per_balance = @wallet.credit_balances.map do |credit_balance|
      credit.where(source_id: credit_balance.id, transaction_date: credit_balance.billed_cycle_for_month(year, month))
    end

    per_balance.reduce(:or) || credit.none
  end

  def transaction_group(scope)
    records = scope.order(transaction_date: :desc, created_at: :desc)

    {
      data: records,
      total_count: records.count,
      total_settled: records.balance(:effective),
      total_projected: records.balance(:projected)
    }
  end

  def set_source
    source_type = params.dig(:transaction, :source_type) || params[:source_type]
    source_id = params.dig(:transaction, :source_id) || params[:source_id]
    @source = find_source(source_type, source_id)
    render json: { message: 'Origem não encontrada.' }, status: :unprocessable_content if @source.nil?
  end

  def find_source(source_type, source_id)
    accessible_wallet_ids = Wallet.accessible_by(@current_user).select("wallets.id")

    case source_type
    when "Account"
      Account.where(wallet_id: accessible_wallet_ids).find_by(id: source_id)
    when "CreditBalance"
      CreditBalance.where(wallet_id: accessible_wallet_ids).find_by(id: source_id)
    end
  end

  def set_transaction
    @transaction = Transaction.where(wallet_id: Wallet.accessible_by(@current_user).select("wallets.id")).find_by(id: params[:id])
    render json: { message: 'Transação não encontrada.' }, status: :unprocessable_content if @transaction.nil?
  end

  def transaction_params
    params.require(:transaction).permit(:description, :value, :kind, :transaction_date, :credit_card_id, :draft)
  end
end
