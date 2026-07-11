class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include JsonWebToken
  include ExceptionHandler
  include ApplicationHelper
  
  before_action :authenticate_fixed_token!
  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  API_FIXED_TOKEN = ENV['API_FIXED_TOKEN'].freeze

  def route_not_found
    render json: { message: "Rota não encontrada: #{request.method} #{request.path}" }, status: :not_found
  end

  # Método exigido pelo Papertrail
  def current_user
    current_user ||= @current_user
  end
  
  private
    def authenticate_fixed_token!
      header = request.headers["X-API-Key"]
      token = header.split(" ").last if header
      return render json: {message: "Token da API não encontrado"}, status: :forbidden if token.nil?

      valid_token = ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(token),
        ::Digest::SHA256.hexdigest(API_FIXED_TOKEN)
      )
      render json: {message: "Token da API inválido"}, status: :forbidden unless valid_token
    end

    def authenticate_user!
      header = request.headers["Authorization"]
      token = header.split(" ").last if header
      return render json: {message: "Autorização não encontrada"}, status: :unauthorized if token.nil?

      decoded = jwt_decode(token)
      @current_user = User.find_by(id: decoded[:user_id])
      return render json: {message: "Usuário inválido"}, status: :unauthorized if @current_user.nil?
    end  
end