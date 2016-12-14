FROM ubuntu:14.04

MAINTAINER backend@velocityapp.com

ENV DATABASE_URL         postgres://postgres@localhost/reservations-db
ENV DEPLOY_MODE          test
ENV NODE_ENV             test
ENV NVM_DIR              /usr/local/nvm
ENV NODE_VERSION         6.9.1
ENV PORT                 8000

RUN usermod -u 1000 www-data
RUN usermod -G staff www-data
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN export DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND noninteractive
RUN dpkg-divert --local --rename --add /sbin/initctl

RUN apt-get -y update
RUN apt-get -y install ca-certificates rpl pwgen git curl

# Install postgres / postgis
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install postgresql-9.5-postgis-2.2
RUN apt-get -y install postgis --without-recommends 

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install base dependencies
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        git \
        libssl-dev \
        python \
        rsync \
        software-properties-common \
        wget \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN echo "postgres:docker" | chpasswd && adduser postgres sudo
RUN echo "local   all             all                                     trust" > /etc/postgresql/9.5/main/pg_hba.conf
RUN echo "host    all             all             127.0.0.1/32            trust" >> /etc/postgresql/9.5/main/pg_hba.conf
RUN echo "host    all             all             ::1/128                 trust" >> /etc/postgresql/9.5/main/pg_hba.conf
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER postgres

RUN service postgresql start &&\
    createdb -O postgres reservations-db &&\
    psql $DATABASE_URL -c 'CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology; CREATE EXTENSION fuzzystrmatch; CREATE EXTENSION postgis_tiger_geocoder;' 1>/dev/null &&\
    service postgresql stop

USER root

# Exclude the NPM cache from the image
VOLUME /root/.npm

RUN mkdir -p /usr/src/app/
WORKDIR /usr/src/app

# Install nvm with node and npm, then migrate the local database
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash \
    && source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Open port 5432 for postgres, 8000 for the app
EXPOSE 5432
EXPOSE 8000
