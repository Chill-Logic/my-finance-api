module ExceptionHandler
  extend ActiveSupport::Concern

  class DecodeError < StandardError; end

  class ExpiredSignature < StandardError; end

  included do
    rescue_from ExceptionHandler::DecodeError do |_error|
      render json: {
        message: 'Acesso negado! O token fornecido é inválido.'
      }, status: :unauthorized
    end
    
    rescue_from ExceptionHandler::ExpiredSignature do |_error|
      render json: {
        message: 'Acesso negado! O token de acesso expirou.'
      }, status: :unauthorized
    end
  end
end
