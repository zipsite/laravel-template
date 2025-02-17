#!/usr/bin/env bash

# Основные переменные переменные (должны быть в самом верху)                #
################################################################

ENV_FILE=./.env
DKCM_FILE=./deploy/conf/web.init.yml
DEPLOY_ENV_FILE=./deploy/conf/deploy.env
DOCKER_COMPOSE="docker compose --env-file $ENV_FILE -f $DKCM_FILE"
RUN_IN_DOCKER="${DOCKER_COMPOSE} exec web start-container"

source $DEPLOY_ENV_FILE

# Создание файлов конфигурации (1 уровень: config layer)

cp docker-compose.dev.yml docker-compose.yml

cp .env.example .env
echo "
WWWGROUP=$(id -g $USER)
WWWUSER=$(id -u $USER)
PROJECT_DIR=$(pwd)" >> .env

# запуск докер контейнера для установки зависимостей php и npm внутри этого контейнера (2 уровень: dependency layer)

# docker rmi forlaravel/1.0
# $DOCKER_COMPOSE build --no-cache web
# $DOCKER_COMPOSE build web
$DOCKER_COMPOSE up -d
# $DOCKER_COMPOSE exec web bash

$RUN_IN_DOCKER "composer install"
$RUN_IN_DOCKER "npm install"

$DOCKER_COMPOSE down

# Запуск основного докер композа и настройка ларавеля (3 уровень: app layer)

DOCKER_COMPOSE="docker compose"
RUN_IN_DOCKER="${DOCKER_COMPOSE} exec web start-container"

$DOCKER_COMPOSE up -d

$RUN_IN_DOCKER "php artisan key:generate"
$RUN_IN_DOCKER "php artisan migrate"

$DOCKER_COMPOSE down
