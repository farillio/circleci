FROM circleci/clojure:lein-2.8.1-node

# Install Ansible and dependencies
RUN sudo apt-get update && \
    sudo apt-get install -y software-properties-common && \
    sudo apt-add-repository 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main' && \
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 && \
    sudo apt-get update && \
    sudo apt-get install -y ansible python-pip postgresql-client && \
    pip install boto boto3 six python-dateutil awscli && \
    echo 'PATH=$PATH:$HOME/.local/bin' >> ~/.profile

# Install Ruby and dependencies
RUN sudo apt-get install make zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev \
                         libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev \
                         libffi-dev default-libmysqlclient-dev libpq-dev rsync imagemagick \
                         chromedriver && \
    wget http://ftp.ruby-lang.org/pub/ruby/2.5/ruby-2.5.1.tar.gz && \
    tar -xzvf ruby-2.5.1.tar.gz && \
    cd ruby-2.5.1 && \
    ./configure && \
    make && \
    sudo make install && \
    cd .. && \
    rm -rf ruby-2.5.1 && \
    rm ruby-2.5.1.tar.gz && \
    sudo gem install bundler

# Add CircleCI deploy and testing tools
RUN wget https://raw.githubusercontent.com/bellkev/circle-lock-test/02d45b47f8bf8e6009aa7fca9e9a7257a77a0404/do-exclusively && \
    chmod +x do-exclusively && \
    sudo cp do-exclusively /usr/local/bin && \
    sudo apt-get install -y jq nginx

USER circleci
WORKDIR /home/circleci

# Add rust toolchain
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain stable -y

ENV PATH=/root/.cargo/bin:$PATH

# Build comrak
RUN . $HOME/.cargo/env && cd /tmp && git clone https://github.com/kivikakk/comrak.git && cd comrak && cargo build --release

ENTRYPOINT ["/bin/bash"]
