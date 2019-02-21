FROM buildpack-deps:bionic

###############################################################################
# Java
#
# http://bit.ly/2AVvMJy
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt-get clean

###############################################################################
# Leiningen/Clojure
#
ENV LEIN_VERSION=2.9.0
ENV LEIN_DOWNLOAD_SHA=628e954e562338abc4f5366e9933c8f0a43fa2b2
ENV LEIN_INSTALL=/usr/local/bin/

WORKDIR /tmp

RUN mkdir -p $LEIN_INSTALL \
  && wget -q https://raw.githubusercontent.com/technomancy/leiningen/$LEIN_VERSION/bin/lein-pkg \
  && echo "Comparing lein-pkg checksum ..." \
  && echo "$LEIN_DOWNLOAD_SHA *lein-pkg" | sha1sum -c - \
  && mv lein-pkg $LEIN_INSTALL/lein \
  && chmod 0755 $LEIN_INSTALL/lein \
  && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip \
  && wget -q https://github.com/technomancy/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.zip.asc \
  && gpg --keyserver pool.sks-keyservers.net --recv-key 2B72BF956E23DE5E830D50F6002AF007D1A7CC18 \
  && echo "Verifying Jar file signature ..." \
  && gpg --verify leiningen-$LEIN_VERSION-standalone.zip.asc \
  && rm leiningen-$LEIN_VERSION-standalone.zip.asc \
  && mkdir -p /usr/share/java \
  && mv leiningen-$LEIN_VERSION-standalone.zip /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar

ENV PATH=$PATH:$LEIN_INSTALL
ENV LEIN_ROOT 1

# Install clojure 1.10.0 so it doesn't have to be downloaded every time
RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.10.0"]])' > project.clj \
  && lein deps && rm project.clj

###############################################################################
# Ruby/Bundler
#
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

# Rubygems version determined from https://rubygems.org/pages/download
ENV RUBYGEMS_VERSION 3.0.2

RUN set -ex \
	\
	&& buildDeps=' \
		bison \
		libgdbm-dev \
		ruby \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& rm -rf /var/lib/apt/lists/* \
	\
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
	&& apt-get purge -y --auto-remove $buildDeps \
	&& cd / \
	&& rm -r /usr/src/ruby \
	\
	&& gem update --system "$RUBYGEMS_VERSION"

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
	&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

###############################################################################
# Node
#
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nodejs libssl1.0-dev nodejs-dev node-gyp npm

###############################################################################
# AWS CLI
#
RUN apt-get update && \
    apt-get install -y python-pip && \
    pip install awscli

###############################################################################
# Ansible
#
RUN pip install ansible
RUN pip install botocore
RUN pip install boto3
RUN pip install boto

###############################################################################
# Postgres Client
#
RUN wget http://apt.postgresql.org/pub/repos/apt/pool/9.6/p/postgresql-9.6/postgresql-client-9.6_9.6~rc1-1.pgdg15.10%2b1_amd64.deb
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
    apt-get install -y postgresql-client-common && \
    dpkg -i postgresql-client-9.6_9.6~rc1-1.pgdg15.10+1_amd64.deb

###############################################################################
# Add CircleCI deploy and testing tools
#
RUN wget https://raw.githubusercontent.com/bellkev/circle-lock-test/02d45b47f8bf8e6009aa7fca9e9a7257a77a0404/do-exclusively && \
    chmod +x do-exclusively && \
    cp do-exclusively /usr/local/bin

###############################################################################
# Chromedriver
#
RUN export CHROMEDRIVER_RELEASE=$(curl --location --fail --retry 3 http://chromedriver.storage.googleapis.com/LATEST_RELEASE) \
    && curl --silent --show-error --location --fail --retry 3 --output /tmp/chromedriver_linux64.zip "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_RELEASE/chromedriver_linux64.zip" \
    && cd /tmp \
    && unzip chromedriver_linux64.zip \
    && rm -rf chromedriver_linux64.zip \
    && mv chromedriver /usr/local/bin/chromedriver \
    && chmod +x /usr/local/bin/chromedriver

###############################################################################
# Other bits and pieces
#
RUN apt-get install -y nginx chromium-browser jq netcat

###############################################################################
# Comrak
#
# Add rust toolchain
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain stable -y

ENV PATH=/root/.cargo/bin:$PATH

# Build and install comrak
RUN . $HOME/.cargo/env && \
    cd /tmp && \
    git clone https://github.com/kivikakk/comrak.git && \
    cd comrak && cargo build --release && cargo install

CMD [ "/bin/bash" ]
