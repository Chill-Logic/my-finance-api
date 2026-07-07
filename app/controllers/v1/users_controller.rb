class V1::UsersController < ApplicationController
  def me
    render json: { data: @current_user }, status: :ok
  end
end
