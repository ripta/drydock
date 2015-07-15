# Dockerfile
# image: ripta/drydock:v1.0
# repo: https://github.com/ripta/drydock.git

FROM gliderlabs/alpine:3.2
MAINTAINER Ripta Pasay <ripta+docker@pasay.name>

LABEL meta.version="1.0" meta.onbuild=true

RUN apk update

# Install the base and dev packages
RUN apk add ruby ruby-dev \
    && apk add nodejs nodejs-dev

# Install the headers and build packages
RUN apk add musl musl-dev \
    && apk add linux-headers \
    && apk add gcc \
    && apk add make \
    && apk add curl curl-dev

RUN curl -sL -o /bin/gosu https://github.com/tianon/gosu/releases/download/1.3/gosu-amd64 \
    && chmod +x /bin/gosu

# This is needed due to the missing trust certificates in alpine linux
RUN gem source --add https://s3.amazonaws.com/production.s3.rubygems.org/ \
    && gem source --remove https://rubygems.org/

# Update to the latest rubygems and install bundler
RUN gem update --system --no-document \
    && gem install --no-document bundler \
    && gem install --no-document unicorn

# Throw build errors if Gemfile has been modified without updating Gemfile.lock
RUN bundle config --global frozen 1 \
    && bundle config --global build.nokogiri --use-system-libraries

# Install bower and gulp
RUN npm install -g bower gulp

# Prepare global environment variables
ENV APPLICATION_ROOT /app

# Build rubygem dependencies
ONBUILD ADD Gemfile ${APPLICATION_ROOT}
ONBUILD ADD Gemfile.lock ${APPLICATION_ROOT}/Gemfile.lock
ONBUILD RUN bundle --path vendor

# Build npm dependencies
ONBUILD ADD package.json ${APPLICATION_ROOT}/package.json
ONBUILD RUN cd ${APPLICATION_ROOT} && npm install

# Copy the application source in
ONBUILD WORKDIR ${APPLICATION_ROOT}
ONBUILD ADD . ${APPLICATION_ROOT}

# Clean up build tools
ONBUILD RUN apk del libffi-dev libxml2-dev libxslt-dev curl-dev \
        && apk del gcc make musl-dev \
        && apk del nodejs-dev ruby-dev
ONBUILD RUN rm -rf /var/cache/apk/*

