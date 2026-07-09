#!/bin/bash
# Executado NO SERVIDOR pelo workflow de deploy (.github/workflows/deploy-dev.yml),
# depois do rsync dos arquivos e da atualização do .env. Roda bundle, migrations
# e reinicia o serviço systemd (processo novo => dotenv relê o .env atualizado).
#
# Na primeira execução cria o serviço de usuário do systemd automaticamente.
# Único passo manual (uma vez, para o serviço sobreviver sem sessão aberta):
#   sudo loginctl enable-linger $USER
set -e

APP_NAME="${1:-my-finance-api}"
SERVICE="${APP_NAME}.service"
cd ~/"$APP_NAME"

# systemctl --user precisa do bus do usuário (sessões ssh não-interativas)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

echo "📦 Instalando dependências..."
bundle install

echo "📑 Rodando migrations..."
bundle exec rails db:migrate

if ! systemctl --user cat "$SERVICE" > /dev/null 2>&1; then
  echo "▶️ Serviço não encontrado. Criando ${SERVICE}..."
  mkdir -p ~/.config/systemd/user
  # rails server (e não puma direto) para o dotenv carregar o .env — incluindo
  # PORT — antes do puma subir; a porta é controlada pelo PORT do .env.
  cat > ~/.config/systemd/user/"$SERVICE" <<UNIT
[Unit]
Description=${APP_NAME} (Rails)
After=network.target

[Service]
WorkingDirectory=%h/${APP_NAME}
ExecStart=/bin/bash -lc 'bundle exec rails server'
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
UNIT
  systemctl --user daemon-reload
  systemctl --user enable --now "$SERVICE"
  loginctl show-user "$USER" --property=Linger | grep -q yes ||
    echo "⚠️ Rode uma vez no servidor: sudo loginctl enable-linger $USER (mantém o app de pé sem sessão aberta)"
else
  echo "🔄 Reiniciando o app (recarrega código e .env)..."
  systemctl --user restart "$SERVICE"
fi

systemctl --user --no-pager --lines=0 status "$SERVICE" | head -3

echo "✅ Deploy finalizado com sucesso!"
