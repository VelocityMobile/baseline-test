FROM ubuntu:16.04

MAINTAINER backend@velocityapp.com

ENV DEBIAN_FRONTEND      noninteractive
ENV DEPLOY_MODE          test
ENV NODE_ENV             test
ENV NVM_DIR              /usr/local/nvm
ENV NVM_VERSION          0.33.6
ENV NODE_VERSION         8.9.1
ENV PORT                 8000

RUN usermod -u 1000 www-data
RUN usermod -G staff www-data
RUN ln -sf /bin/bash /bin/sh

RUN export DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND noninteractive
RUN dpkg-divert --local --rename --add /sbin/initctl

RUN apt-get -y update
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get -y install ca-certificates rpl pwgen git curl wget

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
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

USER root

# Exclude the NPM cache from the image
VOLUME /root/.npm

RUN mkdir -p /usr/src/app/
WORKDIR /usr/src/app

# Install nvm with node and npm, then migrate the local database
RUN curl https://raw.githubusercontent.com/creationix/nvm/v$NVM_VERSION/install.sh | bash \
    && source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH            $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH                 $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
ENV DEBIAN_FRONTEND      ""

# Open port 5432 for postgres, 8000 for the app
EXPOSE 5432
EXPOSE 8000
