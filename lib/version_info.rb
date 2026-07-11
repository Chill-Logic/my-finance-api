# Versão do backend em execução. Prioriza as variáveis de ambiente gravadas pelo CD
# no deploy (GIT_COMMIT_HASH/DATE/BRANCH — usadas pelo deploy de dev); como fallback
# lê as envs nativas do Railway (RAILWAY_GIT_*, injetadas em runtime no auto-deploy);
# em dev/local, onde não há nenhuma dessas, cai no git ao vivo. O Railway não expõe a
# data do commit, então na prod ela cai no fallback (unknown). Usado pelo endpoint
# GET /v1/core/version e pela faixa de versão no topo do Swagger UI (swagger/index.erb).
module VersionInfo
  module_function

  def to_h
    {
      hash: git_info(%w[GIT_COMMIT_HASH RAILWAY_GIT_COMMIT_SHA], 'git rev-parse --short HEAD'),
      date: git_info(%w[GIT_COMMIT_DATE], 'git log -1 --format=%ci'),
      branch: git_info(%w[GIT_BRANCH RAILWAY_GIT_BRANCH], 'git rev-parse --abbrev-ref HEAD')
    }
  end

  def git_info(env_keys, command)
    env_value = Array(env_keys).filter_map { |key| ENV[key].presence }.first
    return env_value if env_value.present?

    `#{command}`.strip.presence || 'unknown'
  rescue StandardError
    'unknown'
  end
end
