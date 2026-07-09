# Versão do backend em execução. Prioriza as variáveis de ambiente gravadas pelo CD
# no deploy (GIT_COMMIT_HASH/DATE/BRANCH); em dev/local, onde não há essas envs,
# cai no git ao vivo. Usado pelo endpoint GET /v1/core/version e pela faixa de
# versão no topo do Swagger UI (swagger/index.erb).
module VersionInfo
  module_function

  def to_h
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
