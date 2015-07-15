# Dockerfile
# image: ripta/drydock:v0.0.2-1.0
# repo: https://github.com/ripta/drydock.git

FROM gliderlabs/alpine:3.2
MAINTAINER Ripta Pasay <ripta+docker@pasay.name>

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

# Install bower and gulp
RUN npm install -g bower gulp

# Prepare global environment variables
ENV APPLICATION_ROOT /app
ENV BUILD_ROOT /build

ONBUILD ADD Gemfile ${BUILD_ROOT}
ONBUILD ADD Gemfile.lock ${BUILD_ROOT}/Gemfile.lock

ONBUILD RUN bundle config build.nokogiri --use-system-libraries \
        && bundle --path vendor

ONBUILD ADD package.json ${BUILD_ROOT}/package.json
ONBUILD RUN cd ${BUILD_ROOT} && npm install

ONBUILD WORKDIR ${APPLICATION_ROOT}

ONBUILD RUN apk del libffi-dev libxml2-dev libxslt-dev curl-dev \
        && apk del gcc make musl-dev \
        && apk del nodejs-dev ruby-dev
ONBUILD RUN rm -rf /var/cache/apk/*


