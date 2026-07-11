class V1::Core::VersionController < V1::Core::CoreController
  def show
    render json: { data: VersionInfo.to_h }, status: :ok
  end
end
