# https://circleci.com/docs/2.0/circleci-images/
FROM circleci/clojure:openjdk-8-lein-2.9.1-browsers

WORKDIR /home/circleci

###############################################################################
# AWS CLI
#
RUN sudo apt-get update && \
    sudo apt-get install -y python-pip && \
    sudo pip install awscli

###############################################################################
# Bundle deps
#
RUN sudo apt-get install -y libpq5 libpq-dev zlib1g-dev

###############################################################################
# Ruby
#
RUN sudo apt-get install ruby ruby-dev bundler

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
    sudo apt-get install -y postgresql-client-common && \
    sudo dpkg -i postgresql-client-9.6_9.6~rc1-1.pgdg15.10+1_amd64.deb && \
    sudo rm -rf postgresql-client-9.6_9.6~rc1-1.pgdg15.10+1_amd64.deb

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

###############################################################################
# Imagemagick
#
RUN sudo apt-get install -y imagemagick

CMD [ "/bin/bash" ]
