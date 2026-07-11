class V1::TransactionsController < ApplicationController
  before_action :set_wallet, only: [:index, :create]
  before_action :set_transaction, only: [:show, :update, :destroy]

  def index
    @transactions = @wallet.transactions.from_date(params[:start_date], params[:timezone]).to_date(params[:end_date], params[:timezone])
    total = @transactions.balance

    @transactions = search_bar(@transactions, params[:terms], ["transactions.description"])
    @transactions = @transactions.order(transaction_date: :desc, created_at: :desc)
    @transactions = paginate(@transactions, params[:page], params[:per_page], total: total)
    render json: @transactions, status: :ok
  end

  def show
    render json: { data: @transaction }, status: :ok
  end

  def create
    @transaction = @wallet.transactions.new(transaction_params.merge(user: @current_user))

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

  def set_transaction
    @transaction = Transaction.where(wallet_id: Wallet.accessible_by(@current_user).select("wallets.id")).find_by(id: params[:id])
    render json: { message: 'Transação não encontrada.' }, status: :unprocessable_content if @transaction.nil?
  end

  def transaction_params
    params.require(:transaction).permit(:description, :value, :kind, :transaction_date)
  end
end
