class V1::UsersController < ApplicationController
  def me
    render json: { data: @current_user }, status: :ok
  end

  def update
    return update_password if user_params[:password].present?

    return render json: { message: @current_user.errors.full_messages.join(', ') }, status: :unprocessable_content unless @current_user.update(profile_params)

    render json: { data: @current_user }, status: :ok
  end

  private

  def update_password
    return render json: { message: 'Senha atual incorreta.' }, status: :unprocessable_content unless @current_user.valid_password?(user_params[:current_password])

    return render json: { message: @current_user.errors.full_messages.join(', ') }, status: :unprocessable_content unless @current_user.update(profile_params.merge(user_params.slice(:password, :password_confirmation)))

    render json: { data: @current_user }, status: :ok
  end

  def profile_params
    user_params.slice(:name, :email)
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end
end
