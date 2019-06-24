# https://circleci.com/docs/2.0/circleci-images/
FROM circleci/clojure:openjdk-8-lein-2.9.1-browsers

WORKDIR /home/circleci

###############################################################################
# Packages
#
RUN sudo apt-get update  \
    && sudo apt-get upgrade -y \
    && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

RUN sudo apt-get update  \
    && sudo apt-get install -y \
    openjdk-8-jdk \
    wget \
    gnupg2 \
    imagemagick \
    locales \
    lsof \
    nginx \
    rsync \
    libpq5 \
    libpq-dev \
    postgresql-client-common \
    zlib1g-dev \
    ruby \
    ruby-dev \
    bundler \
    python-pip \
    vim \
    ssh \
    && sudo apt-get install --no-install-recommends yarn \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

###############################################################################
# clj tool
#
RUN curl -O https://download.clojure.org/install/linux-install-1.10.1.447.sh \
    && chmod +x linux-install-1.10.1.447.sh
RUN sudo ./linux-install-1.10.1.447.sh

###############################################################################
# Make locale the same as Circle CI machine executors
# If they are not the same - collation issues interface with cache keys
#
RUN sudo localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

###############################################################################
# AWS CLI
#
RUN sudo pip install awscli

###############################################################################
# Bundle into Circle CI home directory
#
ENV GEM_HOME /home/circleci/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
    && chmod 700 "$GEM_HOME" "$BUNDLE_BIN"

###############################################################################
# Node
#
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

ENV NODE_VERSION 8.15.0
ENV NVM_DIR /home/circleci/.nvm

RUN . ~/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

###############################################################################
# Postgres Client
#
RUN wget http://apt.postgresql.org/pub/repos/apt/pool/9.6/p/postgresql-9.6/postgresql-client-9.6_9.6~rc1-1.pgdg15.10%2b1_amd64.deb
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get install -y tzdata && \
    sudo dpkg -i postgresql-client-9.6_9.6~rc1-1.pgdg15.10+1_amd64.deb && \
    sudo rm -rf postgresql-client-9.6_9.6~rc1-1.pgdg15.10+1_amd64.deb

###############################################################################
# Comrak
#
# Add rust toolchain
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain stable -y

ENV PATH=/home/circleci/.cargo/bin:$PATH

# Build and install comrak
RUN . /home/circleci/.cargo/env && \
    cd /tmp && \
    git clone https://github.com/kivikakk/comrak.git && \
    cd comrak && cargo build --release && cargo install

CMD [ "/bin/bash" ]
