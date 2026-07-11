class V1::AuthsController < ApplicationController
  skip_before_action :authenticate_user!

  def sign_in
    @user = User.find_by_email(params[:email])

    return render json: {message: "Usuário não encontrado."}, status: :unprocessable_content if @user.nil?

    return render json: {message: "Senha inválida."}, status: :unprocessable_content unless @user.valid_password?(params[:password])

    token = jwt_encode(user_id: @user.id)
    render json: { data: { email: @user.email, name: @user.name, token: token } }, status: :ok
  end

  def sign_up
    @user = User.new(sign_up_params)

    return render json: {message: @user.errors.full_messages.join(', ')}, status: :unprocessable_content unless @user.save

    render json: { message: 'Usuário criado com sucesso!' }, status: :created
  end

  def recover_password
    @user = User.find_by(email: params[:email])

    return render json: {message: "E-mail não encontrado."}, status: :unprocessable_content if @user.nil?

    return render json: {message: @user.errors.full_messages.join(', ')}, status: :unprocessable_content unless @user.send_reset_password_instructions

    render json: {message: "E-mail com instruções enviado com sucesso!"}, status: :ok
  end

  def reset_password
    token = params[:token]
    new_password = params[:password]
    password_confirmation = params[:password_confirmation]

    return render json: {message: "Token e nova senha são obrigatórios."}, status: :unprocessable_content if token.blank? || new_password.blank?

    return render json: {message: "Confirmação de senha não confere."}, status: :unprocessable_content if new_password != password_confirmation

    @user = User.with_reset_password_token(token)

    return render json: {message: "Token inválido."}, status: :unprocessable_content if @user.nil?

    return render json: {message: @user.errors.full_messages.join(', ')}, status: :unprocessable_content unless @user.reset_password(new_password, password_confirmation)

    render json: {message: "Senha alterada com sucesso!"}, status: :ok
  end

  private

  def sign_up_params
    params.permit(:name, :email, :password)
  end
end
