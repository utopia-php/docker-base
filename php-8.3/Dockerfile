FROM php:8.3-cli-alpine as compile

ENV PHP_REDIS_VERSION="6.0.2" \
    PHP_SWOOLE_VERSION="v5.1.2" \
    PHP_IMAGICK_VERSION="3.7.0" \
    PHP_YAML_VERSION="2.2.3" \
    PHP_SCRYPT_VERSION="2.0.1" \
    PHP_BROTLI_VERSION="0.15.0" \
    PHP_XDEBUG_VERSION="3.3.1"

RUN \
  apk add --no-cache --virtual .deps \
  linux-headers \
  icu-dev \
  make \
  automake \
  autoconf \
  gcc \
  g++ \
  git \
  zlib-dev \
  openssl-dev \
  yaml-dev \
  imagemagick \
  imagemagick-dev \
  libjpeg-turbo-dev \
  jpeg-dev \
  libjxl-dev \
  libmaxminddb-dev \
  brotli-dev \
  curl-dev

RUN docker-php-ext-install sockets

FROM compile AS redis
RUN \
  # Redis Extension
  git clone --depth 1 --branch $PHP_REDIS_VERSION https://github.com/phpredis/phpredis.git && \
  cd phpredis && \
  phpize && \
  ./configure && \
  make && make install

## Swoole Extension
FROM compile AS swoole
RUN \
  git clone --depth 1 --branch $PHP_SWOOLE_VERSION https://github.com/swoole/swoole-src.git && \
  cd swoole-src && \
  phpize && \
  ./configure --enable-sockets --enable-http2 --enable-openssl --enable-swoole-curl && \
  make && make install && \
  cd ..

## Imagick Extension
FROM compile AS imagick
RUN \
  git clone --depth 1 --branch $PHP_IMAGICK_VERSION https://github.com/imagick/imagick && \
  cd imagick && \
  phpize && \
  ./configure && \
  make && make install

## YAML Extension
FROM compile AS yaml
RUN \
  git clone --depth 1 --branch $PHP_YAML_VERSION https://github.com/php/pecl-file_formats-yaml && \
  cd pecl-file_formats-yaml && \
  phpize && \
  ./configure && \
  make && make install

## Brotli Extension
FROM compile as brotli
RUN git clone https://github.com/kjdev/php-ext-brotli.git \
  && cd php-ext-brotli \
  && git reset --hard $PHP_BROTLI_VERSION \
  && phpize \
  && ./configure --with-libbrotli \
  && make && make install

## Scrypt Extension
FROM compile AS scrypt
RUN git clone --depth 1 https://github.com/DomBlack/php-scrypt.git  \
  && cd php-scrypt  \
  && git reset --hard $PHP_SCRYPT_VERSION  \
  && phpize  \
  && ./configure --enable-scrypt  \
  && make && make install

## XDebug Extension
FROM compile AS xdebug
RUN \
  git clone --depth 1 --branch $PHP_XDEBUG_VERSION https://github.com/xdebug/xdebug && \
  cd xdebug && \
  phpize && \
  ./configure && \
  make && make install

FROM php:8.3-cli-alpine as final

LABEL maintainer="team@appwrite.io"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN \
  apk update \
  apk add --no-cache \
  libstdc++ \
  rsync \
  brotli-dev \
  yaml-dev \
  imagemagick \
  libjpeg-turbo \
  libjxl \
  libavif \
  libheif \
  imagemagick-heic \
  certbot \
  docker-cli \
  libgomp \
  git \
  && docker-php-ext-install sockets intl \
  && apk del .deps \
  && rm -rf /var/cache/apk/*

WORKDIR /usr/src/code

COPY --from=swoole /usr/local/lib/php/extensions/no-debug-non-zts-20230831/swoole.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=redis /usr/local/lib/php/extensions/no-debug-non-zts-20230831/redis.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=imagick /usr/local/lib/php/extensions/no-debug-non-zts-20230831/imagick.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=yaml /usr/local/lib/php/extensions/no-debug-non-zts-20230831/yaml.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=scrypt /usr/local/lib/php/extensions/no-debug-non-zts-20230831/scrypt.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=brotli /usr/local/lib/php/extensions/no-debug-non-zts-20230831/brotli.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=xdebug /usr/local/lib/php/extensions/no-debug-non-zts-20230831/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/

# Enable Extensions
RUN echo extension=swoole.so >> /usr/local/etc/php/conf.d/swoole.ini
RUN echo extension=redis.so >> /usr/local/etc/php/conf.d/redis.ini
RUN echo extension=imagick.so >> /usr/local/etc/php/conf.d/imagick.ini
RUN echo extension=yaml.so >> /usr/local/etc/php/conf.d/yaml.ini
RUN echo extension=scrypt.so >> /usr/local/etc/php/conf.d/scrypt.ini
RUN echo extension=brotli.so >> /usr/local/etc/php/conf.d/brotli.ini

EXPOSE 80

CMD [ "tail", "-f", "/dev/null" ]