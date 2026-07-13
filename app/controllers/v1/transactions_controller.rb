class V1::TransactionsController < ApplicationController
  before_action :set_wallet, only: [:index]
  before_action :set_source, only: [:create]
  before_action :set_transaction, only: [:show, :update, :destroy, :settle, :unsettle]

  def index
    year, month = resolve_month
    @transactions = filter_by_source(@wallet.transactions.for_month(year, month))

    total_settled = @transactions.balance(:effective)
    total_projected = @transactions.balance(:projected)

    @transactions = search_bar(@transactions, params[:terms], ["transactions.description"])
    @transactions = @transactions.order(transaction_date: :desc, created_at: :desc)
    @transactions = paginate(@transactions, params[:page], params[:per_page], total_settled: total_settled, total_projected: total_projected)
    render json: @transactions, status: :ok
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
