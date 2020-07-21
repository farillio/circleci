# https://circleci.com/docs/2.0/circleci-images/
FROM circleci/clojure:openjdk-11-lein-2.9.1-browsers

WORKDIR /home/circleci

###############################################################################
# Packages
#
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

RUN sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    && sudo apt-get update  \
    && sudo apt-get upgrade -y \
    && sudo apt-get install -y \
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
    mysql-client \
    zlib1g-dev \
    python-pip \
    vim \
    rlwrap \
    ssh \
    autoconf \
    bison \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm-dev \
    && sudo apt-get install --no-install-recommends yarn \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

###############################################################################
# Postgresql
#
RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" >>/etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
    && sudo apt-get update \
    && sudo apt-get install postgresql-client-9.6

###############################################################################
# Ruby/Bundler (as root)
#
USER root

# Ref: http://bit.ly/2AVMEQp
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

# SHA from http://bit.ly/2koIl5u
ENV RUBY_MAJOR=2.6
ENV RUBY_VERSION=2.6.1
ENV RUBY_DOWNLOAD_SHA256=17024fb7bb203d9cf7a5a42c78ff6ce77140f9d083676044a7db67f1e5191cb8
ENV RUBYGEMS_VERSION=3.0.2
ENV BUNDLER_VERSION=1.13.6
ENV RAKE_VERSION=12.3.3

RUN set -ex \
	&& wget -O ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.gz" \
	&& echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
	\
	&& mkdir -p /usr/src/ruby \
	&& tar xvfz ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
	&& rm ruby.tar.gz \
	\
	&& cd /usr/src/ruby \
	&& { \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new \
	&& mv file.c.new file.c \
	\
	&& autoconf \
	&& ./configure --disable-install-doc --enable-shared \
	&& make -j"$(nproc)" \
	&& make install \
	\
	&& cd / \
	&& rm -r /usr/src/ruby \
	\
	&& gem update --system "$RUBYGEMS_VERSION"

USER circleci

# Bundle into Circle CI home directory
ENV GEM_HOME /home/circleci/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
    && chmod 700 "$GEM_HOME" "$BUNDLE_BIN"

# Bundler
RUN gem install bundler -v "$BUNDLER_VERSION"

# Rake
RUN gem install rake -v "$RAKE_VERSION"

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
# Node
#
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

ENV NODE_VERSION 12.3.1
ENV NVM_DIR /home/circleci/.nvm

RUN . ~/.nvm/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

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

RUN curl -s https://raw.githubusercontent.com/borkdude/babashka/master/install | sudo /bin/bash

CMD [ "/bin/bash" ]
