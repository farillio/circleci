# https://circleci.com/docs/2.0/circleci-images/
FROM circleci/clojure:openjdk-8-lein-2.9.1-node-browsers

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

CMD [ "/bin/bash" ]
