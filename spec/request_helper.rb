require 'rails_helper'

module RequestHelper
  include JsonWebToken

  MISSING_UUID = "00000000-0000-0000-0000-000000000000".freeze

  def make_request(request)
    endpoint = request[:endpoint]
    params = request[:params]
    token = request[:token]
    headers = { "X-API-Key" => ENV["API_FIXED_TOKEN"] }
    headers = headers.merge({ "Authorization" => "Bearer #{token}" }) if token.present?
    
    send(request[:method], endpoint, headers: headers, params: params)
  end

  def user_token
    jwt_encode(user_id: users(:gabriel).id)
  end

  def second_user_token
    jwt_encode(user_id: users(:maria).id)
  end

  def expired_token
    jwt_encode({ user_id: users(:gabriel).id }, 7.days.ago)
  end

  def invalid_token
    "invalid_token"
  end
end
