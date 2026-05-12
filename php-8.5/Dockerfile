FROM php:8.5-cli-alpine AS compile

ENV PHP_REDIS_VERSION="6.3.0" \
    PHP_SWOOLE_VERSION="v6.2.0" \
    PHP_IMAGICK_VERSION="3.8.1" \
    PHP_YAML_VERSION="2.3.0" \
    PHP_MAXMINDDB_VERSION="v1.12.0" \
    PHP_SCRYPT_VERSION="2.0.1" \
    PHP_ZSTD_VERSION="d6d26eb805058fc672686715a7b5e39d8f65dd36" \
    PHP_BROTLI_VERSION="0.18.3" \
    PHP_SNAPPY_VERSION="ddc8b58d8892593695a17c2b83d72ba3e9f41f64" \
    PHP_LZ4_VERSION="bf27b2c13922b6fbeb2eac5251be4e8a95d01e36" \
    PHP_XDEBUG_VERSION="3.5.1" \
    PHP_MONGO_VERSION="2.2.1"

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
  zstd-dev \
  brotli-dev \
  lz4-dev \
  curl-dev \
  cmake

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

## Maxminddb extension
FROM compile AS maxmind
RUN \
  git clone --depth 1 --branch $PHP_MAXMINDDB_VERSION https://github.com/maxmind/MaxMind-DB-Reader-php.git && \
  cd MaxMind-DB-Reader-php && \
  cd ext && \
  phpize && \
  ./configure && \
  make && make install

# Zstd Compression
FROM compile AS zstd
RUN git clone --recursive -n https://github.com/kjdev/php-ext-zstd.git \
  && cd php-ext-zstd \
  && git checkout $PHP_ZSTD_VERSION \
  && phpize \
  && ./configure --with-libzstd \
  && make && make install

## Brotli Extension
FROM compile AS brotli
RUN git clone https://github.com/kjdev/php-ext-brotli.git \
  && cd php-ext-brotli \
  && git reset --hard $PHP_BROTLI_VERSION \
  && phpize \
  && ./configure --with-libbrotli \
  && make && make install

## LZ4 Extension
FROM compile AS lz4
RUN git clone --recursive https://github.com/kjdev/php-ext-lz4.git \
  && cd php-ext-lz4 \
  && git reset --hard $PHP_LZ4_VERSION \
  && phpize \
  && ./configure --with-lz4-includedir=/usr \
  && make && make install

## Snappy Extension
FROM compile AS snappy
RUN git clone --recursive https://github.com/kjdev/php-ext-snappy.git \
  && cd php-ext-snappy \
  && git reset --hard $PHP_SNAPPY_VERSION \
  && phpize \
  && ./configure \
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

## MongoDB Extension
FROM compile AS mongodb
RUN \
  git clone --depth 1 --recursive --branch $PHP_MONGO_VERSION https://github.com/mongodb/mongo-php-driver.git && \
  cd mongo-php-driver && \
  phpize && \
  ./configure && \
  make && make install

FROM php:8.5-cli-alpine AS final

LABEL maintainer="team@appwrite.io"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN \
  apk update \
  && apk add --no-cache \
  linux-headers \
  rsync \
  brotli-dev \
  lz4-dev \
  zstd-dev \
  yaml-dev \
  imagemagick \
  libjpeg-turbo \
  libjxl \
  libavif \
  libheif \
  imagemagick-heic \
  libgomp \
  libwebp \
  git \
  && rm -rf /var/cache/apk/*

RUN  docker-php-ext-install sockets

WORKDIR /usr/src/code

COPY --from=swoole /usr/local/lib/php/extensions/no-debug-non-zts-20250925/swoole.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=redis /usr/local/lib/php/extensions/no-debug-non-zts-20250925/redis.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=imagick /usr/local/lib/php/extensions/no-debug-non-zts-20250925/imagick.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=yaml /usr/local/lib/php/extensions/no-debug-non-zts-20250925/yaml.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=scrypt /usr/local/lib/php/extensions/no-debug-non-zts-20250925/scrypt.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=zstd /usr/local/lib/php/extensions/no-debug-non-zts-20250925/zstd.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=brotli /usr/local/lib/php/extensions/no-debug-non-zts-20250925/brotli.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=lz4 /usr/local/lib/php/extensions/no-debug-non-zts-20250925/lz4.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=snappy /usr/local/lib/php/extensions/no-debug-non-zts-20250925/snappy.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=xdebug /usr/local/lib/php/extensions/no-debug-non-zts-20250925/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/
COPY --from=mongodb /usr/local/lib/php/extensions/no-debug-non-zts-20250925/mongodb.so /usr/local/lib/php/extensions/no-debug-non-zts-20250925/

# Enable Extensions
RUN echo extension=swoole.so >> /usr/local/etc/php/conf.d/swoole.ini
RUN echo extension=redis.so >> /usr/local/etc/php/conf.d/redis.ini
RUN echo extension=imagick.so >> /usr/local/etc/php/conf.d/imagick.ini
RUN echo extension=yaml.so >> /usr/local/etc/php/conf.d/yaml.ini
RUN echo extension=scrypt.so >> /usr/local/etc/php/conf.d/scrypt.ini
RUN echo extension=zstd.so >> /usr/local/etc/php/conf.d/zstd.ini
RUN echo extension=brotli.so >> /usr/local/etc/php/conf.d/brotli.ini
RUN echo extension=lz4.so >> /usr/local/etc/php/conf.d/lz4.ini
RUN echo extension=snappy.so >> /usr/local/etc/php/conf.d/snappy.ini
RUN echo extension=mongodb.so >> /usr/local/etc/php/conf.d/mongodb.ini

EXPOSE 80

CMD [ "tail", "-f", "/dev/null" ]
