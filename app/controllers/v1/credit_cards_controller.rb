class V1::CreditCardsController < ApplicationController
  before_action :set_credit_balance, only: [:index, :create]
  before_action :set_credit_card, only: [:show, :update, :destroy]

  def index
    @credit_cards = @credit_balance.credit_cards
    @credit_cards = search_bar(@credit_cards, params[:terms], ["credit_cards.name"])
    @credit_cards = paginate(@credit_cards, params[:page], params[:per_page])
    render json: @credit_cards, status: :ok
  end

  def show
    render json: { data: @credit_card }, status: :ok
  end

  def create
    @credit_card = @credit_balance.credit_cards.new(credit_card_params)

    return render json: { message: @credit_card.errors.full_messages.join(', ') }, status: :unprocessable_content unless @credit_card.save

    render json: { data: @credit_card }, status: :created
  end

  def update
    return render json: { message: @credit_card.errors.full_messages.join(', ') }, status: :unprocessable_content unless @credit_card.update(credit_card_params)

    render json: { data: @credit_card }, status: :ok
  end

  def destroy
    return render json: { message: @credit_card.errors.full_messages.join(', ') }, status: :unprocessable_content unless @credit_card.discard

    render json: { message: 'Cartão removido com sucesso!' }, status: :ok
  end

  private

  def set_credit_balance
    credit_balance_id = params[:credit_balance_id] || params.dig(:credit_card, :credit_balance_id)
    @credit_balance = CreditBalance.accessible_by(@current_user).find_by(id: credit_balance_id)
    render json: { message: 'Saldo de crédito não encontrado.' }, status: :unprocessable_content if @credit_balance.nil?
  end

  def set_credit_card
    @credit_card = CreditCard.accessible_by(@current_user).find_by(id: params[:id])
    render json: { message: 'Cartão não encontrado.' }, status: :unprocessable_content if @credit_card.nil?
  end

  def credit_card_params
    params.require(:credit_card).permit(:name, :last_digits)
  end
end
