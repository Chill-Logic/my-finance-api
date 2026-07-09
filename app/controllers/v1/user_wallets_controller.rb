class V1::UserWalletsController < ApplicationController
  before_action :set_user_wallet, only: [:accept, :reject]

  def index
    @user_wallets = @current_user.user_wallets.pending
    @user_wallets = paginate(@user_wallets, params[:page], params[:per_page])
    render json: @user_wallets, status: :ok
  end

  def create
    guest = User.find_by(email: user_wallet_params[:user_email])

    return render json: { message: 'Não foi encontrado usuário com esse e-mail.' }, status: :unprocessable_content if guest.nil?

    wallet = @current_user.owned_wallets.find_by(id: user_wallet_params[:wallet_id])

    return render json: { message: 'Carteira não encontrada.' }, status: :unprocessable_content if wallet.nil?

    @user_wallet = UserWallet.new(user: guest, wallet: wallet)

    return render json: { message: @user_wallet.errors.full_messages.join(', ') }, status: :unprocessable_content unless @user_wallet.save

    render json: { message: 'Usuário convidado com sucesso!' }, status: :created
  end

  def accept
    return render json: { message: @user_wallet.errors.full_messages.join(', ') }, status: :unprocessable_content unless @user_wallet.update(accepted: true)

    render json: { message: 'Convite aceito com sucesso!' }, status: :ok
  end

  def reject
    return render json: { message: @user_wallet.errors.full_messages.join(', ') }, status: :unprocessable_content unless @user_wallet.discard

    render json: { message: 'Convite recusado com sucesso!' }, status: :ok
  end

  private

  def set_user_wallet
    @user_wallet = @current_user.user_wallets.pending.find_by(id: params[:id])
    render json: { message: 'Convite não encontrado ou já respondido.' }, status: :unprocessable_content if @user_wallet.nil?
  end

  def user_wallet_params
    params.require(:user_wallet).permit(:user_email, :wallet_id)
  end
end
