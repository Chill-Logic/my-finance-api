#!/bin/bash
set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Uso: ./local-deploy.sh <REMOTE_USER> <REMOTE_HOST>"
  exit 1
fi

REMOTE_USER=$1
REMOTE_HOST=$2
APP_NAME="my-finance-api"

rsync -avz --delete --relative --progress \
  --exclude '.bundle' \
  --exclude 'log/*' \
  --exclude 'tmp/*' \
  --exclude 'storage/*' \
  --exclude 'coverage' \
  --exclude '.git/*' \
  -e "ssh -o ProxyCommand='cloudflared access ssh --hostname ${REMOTE_HOST}'" \
  ./ ${REMOTE_USER}@${REMOTE_HOST}:~/${APP_NAME}
