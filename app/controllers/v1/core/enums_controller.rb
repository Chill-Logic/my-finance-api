class V1::Core::EnumsController < V1::Core::CoreController
  def options
    @entity = params[:entity]
    @type = params[:type]
    enum_options = ApplicationHelper.enum_options(@entity, @type)

    return render json: { message: enum_options[:message] }, status: :unprocessable_entity if enum_options[:error?]

    render json: { data: enum_options[:options] }, status: :ok
  end
end