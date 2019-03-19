# https://circleci.com/docs/2.0/circleci-images/
FROM circleci/clojure:openjdk-8-lein-2.9.1-node-browsers

###############################################################################
# AWS CLI
#
RUN apt-get update && \
    apt-get install -y python-pip && \
    pip install awscli

###############################################################################
# Postgres Client
#
RUN wget http://apt.postgresql.org/pub/repos/apt/pool/9.6/p/postgresql-9.6/postgresql-client-9.6_9.6~rc1-1.pgdg15.10%2b1_amd64.deb
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
    apt-get install -y postgresql-client-common && \
    dpkg -i postgresql-client-9.6_9.6~rc1-1.pgdg15.10+1_amd64.deb

###############################################################################
# Ruby
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

CMD [ "/bin/bash" ]
