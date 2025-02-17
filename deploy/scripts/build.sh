#!/bin/bash

DEPLOY_ENV_FILE=./deploy/conf/deploy.env

# Читаем переменные из .env файла и сохраняем их в массив
args=""
while IFS='=' read -r key value; do
    # Пропускаем пустые строки или строки с комментариями
    if [[ -n "$key" && ! "$key" =~ ^# ]]; then
        args="$args --build-arg $key=$value"
    fi
done < $DEPLOY_ENV_FILE

echo $args

