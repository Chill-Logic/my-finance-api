set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "O arquivo deve ser executado da seguinte forma: ./deploy.sh <REMOTE_USER> <REMOTE_HOST>"
  exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2
APP_NAME="my-finance-api-prod"

echo "🚀 Iniciando deploy..."

rsync -avz --delete --relative --progress --exclude 'node_modules' --exclude 'dist' \
  -e "ssh -o ProxyCommand='cloudflared access ssh --hostname ${REMOTE_HOST}'" \
  ./ ${REMOTE_USER}@${REMOTE_HOST}:~/${APP_NAME}

ssh -T \
  -o "ProxyCommand=cloudflared access ssh --hostname ${REMOTE_HOST}" \
  ${REMOTE_USER}@${REMOTE_HOST} << EOF
  set -e
  cd ~/${APP_NAME}

  echo "📦 Instalando dependências..."
  npm ci

  echo "🏗️  Buildando projeto..."
  npm run build

  echo "📑 Rodando migrations..."
  npx mikro-orm migration:up

  echo "🔍 Verificando se o app já está rodando no PM2..."
  if pm2 describe ${APP_NAME} > /dev/null 2>&1; then
    echo "🔄 App encontrado. Recarregando com PM2..."
    pm2 reload ${APP_NAME}
  else
    echo "▶️ App não encontrado. Iniciando nova instância com PM2..."
    pm2 start dist/main.js --name ${APP_NAME}
  fi

  echo "💾 Salvando estado do PM2..."
  pm2 save

  echo "✅ Deploy finalizado com sucesso!"
EOF
