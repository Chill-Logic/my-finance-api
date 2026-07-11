class V1::Core::CoreController < ApplicationController
  skip_before_action :authenticate_user!
end