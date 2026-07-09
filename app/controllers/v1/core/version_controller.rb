class V1::Core::VersionController < V1::Core::CoreController
  def show
    render json: { data: version_info }, status: :ok
  end

  private

    def version_info
      {
        hash: git_info('GIT_COMMIT_HASH', 'git rev-parse --short HEAD'),
        date: git_info('GIT_COMMIT_DATE', 'git log -1 --format=%ci'),
        branch: git_info('GIT_BRANCH', 'git rev-parse --abbrev-ref HEAD')
      }
    end

    def git_info(env_key, command)
      env_value = ENV[env_key]
      return env_value if env_value.present?

      `#{command}`.strip.presence || 'unknown'
    rescue StandardError
      'unknown'
    end
end
