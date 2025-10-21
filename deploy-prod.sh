set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "O arquivo deve ser executado da seguinte forma: ./deploy.sh <REMOTE_USER> <REMOTE_HOST> <SSH_PORT>"
  exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2
SSH_PORT=$3
APP_NAME="my-finance-api-prod"

echo "🚀 Iniciando deploy..."

rsync -avz --delete --relative --progress --exclude 'node_modules' --exclude 'dist' -e "ssh -p ${SSH_PORT}" ./ ${REMOTE_USER}@${REMOTE_HOST}:~/${APP_NAME}

ssh -T -p ${SSH_PORT} ${REMOTE_USER}@${REMOTE_HOST} << EOF
  set -e
  cd ~/${APP_NAME}

  echo "📦 Instalando dependências..."
  npm ci

  echo "📑 Gerando Prisma Client..."
  npx prisma generate

  echo "🏗️  Buildando projeto..."
  npm run build

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
