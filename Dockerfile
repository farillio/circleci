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
# Postgres Client
#
RUN wget http://apt.postgresql.org/pub/repos/apt/pool/9.6/p/postgresql-9.6/postgresql-client-9.6_9.6~rc1-1.pgdg15.10%2b1_amd64.deb
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get install -y tzdata && \
    sudo apt-get install -y postgresql-client-common && \
    sudo dpkg -i postgresql-client-9.6_9.6~rc1-1.pgdg15.10+1_amd64.deb && \
    sudo rm -rf postgresql-client-9.6_9.6~rc1-1.pgdg15.10%2b1_amd64.deb

###############################################################################
# Bundle deps
#
RUN sudo apt-get install -y libpq5 libpq-dev zlib1g-dev

###############################################################################
# Ruby
#
RUN sudo apt-get install ruby ruby-dev bundler

CMD [ "/bin/bash" ]
