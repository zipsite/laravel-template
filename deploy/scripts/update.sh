#!/usr/bin/env bash

# Основные переменные переменные (должны быть в самом верху)                #
################################################################

ENV_FILE=./.env
DKCM_FILE=./deploy/conf/web.init.yml
DEPLOY_ENV_FILE=./deploy/conf/deploy.env
DOCKER_COMPOSE="docker compose --env-file $ENV_FILE -f $DKCM_FILE"
RUN_IN_DOCKER="${DOCKER_COMPOSE} exec web start-container"

source $DEPLOY_ENV_FILE
