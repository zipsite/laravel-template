#!/usr/bin/env bash

#####################################################
# Этот скрипт помогает быстро создать новый проект  #
# laravel в докере, без запуска самого сервера      #
#####################################################

# Основные переменные переменные (должны быть в самом верху)                #
################################################################

ENV_FILE=./.env
DKCM_FILE=./deploy/conf/web.init.yml
DEPLOY_ENV_FILE=./deploy/conf/deploy.env

UPDATE_ENV_VARS=./deploy/scripts/lib/updateEnvVars.sh

source $DEPLOY_ENV_FILE

#     Клонирование репозитория laravel (до запуска docker compose)     #
################################################################

git clone https://github.com/laravel/laravel.git
cd laravel
git checkout $LARAVEL_VERSION
git pull
rm -rf .github .git
cp -a ./. ../
cd ..
rm -rf laravel

# Создание файлов конфигурации (1 уровень: config layer)

echo "/mysql
/docker-compose.yml" >> .gitignore

cp -f docker-compose.dev.yml docker-compose.yml
cp -f .env.example .env

# Редактирование .env файла

declare -A env_vars=(
    ["APP_PORT"]="8000"
    ["APP_URL"]="http://localhost:\${APP_PORT}"
)
$UPDATE_ENV_VARS --env-file $ENV_FILE --start-marker "APP_URL" "${env_vars[@]}"

declare -A env_vars=(
    ["DB_CONNECTION"]="mysql"
    ["DB_HOST"]="mysql"
    ["DB_PORT"]="3306"
    ["DB_DATABASE"]="laravel"
    ["DB_USERNAME"]="docker"
    ["DB_PASSWORD"]="docker"
)
$UPDATE_ENV_VARS --env-file $ENV_FILE --start-marker "DB_CONNECTION" --end-marker "DB_PASSWORD" "${env_vars[@]}"

declare -A env_vars=(
    ["WWWGROUP"]="$(id -g $USER)"
    ["WWWUSER"]="$(id -u $USER)"
    ["PROJECT_DIR"]="$(pwd)"
)
$UPDATE_ENV_VARS --env-file $ENV_FILE "${env_vars[@]}"

# cat $DEPLOY_ENV_FILE >> .env

# БИЛД ОБРАЗА ДОКЕР

# Читаем переменные из .env файла и сохраняем их в массив
args=""
while IFS='=' read -r key value; do
    # Пропускаем пустые строки или строки с комментариями
    if [[ -n "$key" && ! "$key" =~ ^# ]]; then
        args="$args --build-arg $key=$value"
    fi
done < $DEPLOY_ENV_FILE

# Команда для сборки Docker образа
docker build \
    $args \
    -t $IMAGE_NAME \
    -f $DOCKERFILE_PATH \
    $BUILD_CONTEXT

# Запуск деплойного контейнера докер, в нём нет ничего лишнего #
################################################################
DOCKER_COMPOSE="docker compose --env-file $ENV_FILE -f $DKCM_FILE"
RUN_IN_DOCKER="${DOCKER_COMPOSE} exec web start-container"
$DOCKER_COMPOSE up -d


# установка зависимостей проекта (нужен контейнер)             #
################################################################

$RUN_IN_DOCKER "composer install"
$RUN_IN_DOCKER "npm install"

# Настройка ларавеля (3 уровень: app layer) #


$DOCKER_COMPOSE down


DOCKER_COMPOSE="docker compose"
RUN_IN_DOCKER="${DOCKER_COMPOSE} exec web start-container"

$DOCKER_COMPOSE up -d

$RUN_IN_DOCKER "php artisan key:generate"
$RUN_IN_DOCKER "php artisan install:api"
$RUN_IN_DOCKER "php artisan migrate"

$DOCKER_COMPOSE down


