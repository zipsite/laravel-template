FROM ubuntu:22.04

LABEL maintainer="Taylor Otwell"

ARG WWWGROUP
ARG NODE_VERSION=20
ARG POSTGRES_VERSION=15
ARG PHP_VERSION=8.3

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Moscow
ENV SUPERVISOR_PHP_COMMAND="/usr/bin/php -d variables_order=EGPCS /var/www/html/artisan serve --host=0.0.0.0 --port=8000"
ENV SUPERVISOR_PHP_USER="sail"
ENV WEB_CONTAINER_DIR="/var/www/html/web-container"
ENV PHP=php${PHP_VERSION}

# Установка временной зоны
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Установка основных системных пакетов
RUN apt-get update \
    && mkdir -p /etc/apt/keyrings \
    && apt-get install -y \
        gnupg \
        gosu \
        curl \
        ca-certificates \
        zip \
        unzip \
        git \
        supervisor \
        sqlite3 \
        libcap2-bin \
        libpng-dev \
        dnsutils \
        librsvg2-bin \
        fswatch \
        nano \
        inetutils-ping \
        cron

# Установка PHP
RUN curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y \
        $PHP-cli \
        # $PHP-dev \
        $PHP-sqlite3 \
        $PHP-curl \
        $PHP-mysql \
        $PHP-mbstring \
        $PHP-xml \
        $PHP-zip \
        $PHP-bcmath \
        $PHP-soap \
        $PHP-intl \
        $PHP-readline \
        $PHP-ldap \
        $PHP-msgpack \
        $PHP-igbinary \
        $PHP-swoole \
        $PHP-pcov \
        $PHP-gd \
        $PHP-xdebug

# Установка Composer
RUN curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# Установка Node.js
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm

# Установка MySQL клиента
RUN apt-get update \
    && apt-get install -y mysql-client

# Очистка кеша менеджера пакетов
RUN apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Настройка фаервола для php
RUN setcap "cap_net_bind_service=+ep" /usr/bin/$PHP

RUN groupadd --force -g $WWWGROUP sail \
    && useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 sail


RUN rm -rf /etc/supervisor \
    && ln -s $WEB_CONTAINER_DIR/etc/supervisor /etc/supervisor \
    && rm -rf /var/log/supervisor \
    && ln -s $WEB_CONTAINER_DIR/var/log/supervisor /var/log/supervisor \
    && ln -s $WEB_CONTAINER_DIR/etc/cron.d/sail /etc/cron.d/sail \
    && ln -s $WEB_CONTAINER_DIR/etc/php.ini /etc/php/8.3/cli/conf.d/99-sail.ini \
    && ln -s $WEB_CONTAINER_DIR/start-container /usr/local/bin/start-container


EXPOSE 8000
