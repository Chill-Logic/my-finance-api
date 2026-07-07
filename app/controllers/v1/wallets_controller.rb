class V1::WalletsController < ApplicationController
  before_action :set_wallet, only: [:show, :update, :destroy]
  before_action :authenticate_owner, only: [:update, :destroy]

  def index
    @wallets = Wallet.accessible_by(@current_user)
    @wallets = search_bar(@wallets, params[:terms], ["wallets.name"])
    @wallets = paginate(@wallets, params[:page], params[:per_page])
    render json: @wallets, status: :ok
  end

  def main
    @wallet = @current_user.main_user_wallet&.wallet

    return render json: { message: 'Carteira principal não encontrada.' }, status: :unprocessable_entity if @wallet.nil?

    render json: { data: @wallet }, status: :ok
  end

  def show
    render json: { data: @wallet }, status: :ok
  end

  def create
    @wallet = Wallet.new(wallet_params.merge(owner: @current_user))

    return render json: { message: @wallet.errors.full_messages.join(', ') }, status: :unprocessable_entity unless @wallet.save

    render json: { data: @wallet }, status: :created
  end

  def update
    return render json: { message: @wallet.errors.full_messages.join(', ') }, status: :unprocessable_entity unless @wallet.update(wallet_params)

    render json: { data: @wallet }, status: :ok
  end

  def destroy
    return render json: { message: @wallet.errors.full_messages.join(', ') }, status: :unprocessable_entity unless @wallet.discard

    render json: { message: 'Carteira removida com sucesso!' }, status: :ok
  end

  private

  def set_wallet
    @wallet = Wallet.accessible_by(@current_user).find_by(id: params[:id])
    render json: { message: 'Carteira não encontrada.' }, status: :unprocessable_entity if @wallet.nil?
  end

  def authenticate_owner
    return render json: { message: 'Apenas o dono da carteira pode realizar essa ação.' }, status: :forbidden unless @wallet.owner_id == @current_user.id
  end

  def wallet_params
    params.require(:wallet).permit(:name)
  end
end
