class V1::AccountsController < ApplicationController
  before_action :set_wallet, only: [:index, :create]
  before_action :set_account, only: [:show, :update, :destroy]

  def index
    @accounts = @wallet.accounts
    @accounts = search_bar(@accounts, params[:terms], ["accounts.name"])
    @accounts = paginate(@accounts, params[:page], params[:per_page])
    render json: @accounts, status: :ok
  end

  def show
    render json: { data: @account }, status: :ok
  end

  def create
    @account = @wallet.accounts.new(account_params)

    return render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_content unless @account.save

    render json: { data: @account }, status: :created
  end

  def update
    return render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_content unless @account.update(account_params)

    render json: { data: @account }, status: :ok
  end

  def destroy
    return render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_content unless @account.discard

    render json: { message: 'Conta removida com sucesso!' }, status: :ok
  end

  private

  def set_wallet
    wallet_id = params[:wallet_id] || params.dig(:account, :wallet_id)
    @wallet = Wallet.accessible_by(@current_user).find_by(id: wallet_id)
    render json: { message: 'Carteira não encontrada.' }, status: :unprocessable_content if @wallet.nil?
  end

  def set_account
    @account = Account.accessible_by(@current_user).find_by(id: params[:id])
    render json: { message: 'Conta não encontrada.' }, status: :unprocessable_content if @account.nil?
  end

  def account_params
    params.require(:account).permit(:name, :kind, :initial_balance)
  end
end
