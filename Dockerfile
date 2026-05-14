ARG PHP_VERSION=8.5
ARG PHP_API

FROM php:${PHP_VERSION}-cli-alpine AS compile
ARG PHP_API
ARG PHP_REDIS_VERSION
ARG PHP_SWOOLE_VERSION
ARG PHP_IMAGICK_VERSION
ARG PHP_YAML_VERSION
ARG PHP_MAXMINDDB_VERSION
ARG PHP_SCRYPT_VERSION
ARG PHP_ZSTD_VERSION
ARG PHP_BROTLI_VERSION
ARG PHP_SNAPPY_VERSION
ARG PHP_LZ4_VERSION
ARG PHP_XDEBUG_VERSION
ARG PHP_MONGO_VERSION

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
  binutils \
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

RUN docker-php-ext-install sockets && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/sockets.so

FROM compile AS redis
RUN \
  git clone --depth 1 --branch $PHP_REDIS_VERSION https://github.com/phpredis/phpredis.git && \
  cd phpredis && \
  phpize && \
  ./configure && \
  make && make install && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS swoole
RUN \
  git clone --depth 1 --branch $PHP_SWOOLE_VERSION https://github.com/swoole/swoole-src.git && \
  cd swoole-src && \
  phpize && \
  ./configure --enable-sockets --enable-http2 --enable-openssl --enable-swoole-curl && \
  make && make install && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so && \
  cd ..

FROM compile AS imagick
RUN \
  git clone --depth 1 --branch $PHP_IMAGICK_VERSION https://github.com/imagick/imagick && \
  cd imagick && \
  phpize && \
  ./configure && \
  make && make install && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS yaml
RUN \
  git clone --depth 1 --branch $PHP_YAML_VERSION https://github.com/php/pecl-file_formats-yaml && \
  cd pecl-file_formats-yaml && \
  phpize && \
  ./configure && \
  make && make install && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS maxmind
RUN \
  git clone --depth 1 --branch $PHP_MAXMINDDB_VERSION https://github.com/maxmind/MaxMind-DB-Reader-php.git && \
  cd MaxMind-DB-Reader-php && \
  cd ext && \
  phpize && \
  ./configure && \
  make && make install && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS zstd
RUN git clone --recursive -n https://github.com/kjdev/php-ext-zstd.git \
  && cd php-ext-zstd \
  && git checkout $PHP_ZSTD_VERSION \
  && phpize \
  && ./configure --with-libzstd \
  && make && make install \
  && strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS brotli
RUN git clone https://github.com/kjdev/php-ext-brotli.git \
  && cd php-ext-brotli \
  && git reset --hard $PHP_BROTLI_VERSION \
  && phpize \
  && ./configure --with-libbrotli \
  && make && make install \
  && strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS lz4
RUN git clone --recursive https://github.com/kjdev/php-ext-lz4.git \
  && cd php-ext-lz4 \
  && git reset --hard $PHP_LZ4_VERSION \
  && phpize \
  && ./configure --with-lz4-includedir=/usr \
  && make && make install \
  && strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS snappy
RUN git clone --recursive https://github.com/kjdev/php-ext-snappy.git \
  && cd php-ext-snappy \
  && git reset --hard $PHP_SNAPPY_VERSION \
  && phpize \
  && ./configure \
  && make && make install \
  && strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS scrypt
RUN git clone --depth 1 https://github.com/DomBlack/php-scrypt.git  \
  && cd php-scrypt  \
  && git reset --hard $PHP_SCRYPT_VERSION  \
  && phpize  \
  && ./configure --enable-scrypt  \
  && make && make install \
  && strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS xdebug
RUN \
  git clone --depth 1 --branch $PHP_XDEBUG_VERSION https://github.com/xdebug/xdebug && \
  cd xdebug && \
  phpize && \
  ./configure && \
  make && make install && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM compile AS mongodb
RUN \
  git clone --depth 1 --recursive --branch $PHP_MONGO_VERSION https://github.com/mongodb/mongo-php-driver.git && \
  cd mongo-php-driver && \
  phpize && \
  ./configure && \
  make && make install && \
  strip --strip-unneeded /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/*.so

FROM php:${PHP_VERSION}-cli-alpine AS final
ARG PHP_API

LABEL maintainer="team@appwrite.io"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN \
  apk add --no-cache \
  rsync \
  brotli-libs \
  lz4-libs \
  zstd-libs \
  yaml \
  imagemagick \
  libjpeg-turbo \
  libjxl \
  libavif \
  libheif \
  imagemagick-heic \
  libgomp \
  libwebp \
  git

WORKDIR /usr/src/code

COPY --from=compile /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/sockets.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=compile /usr/local/etc/php/conf.d/docker-php-ext-sockets.ini /usr/local/etc/php/conf.d/
COPY --from=swoole /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/swoole.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=redis /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/redis.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=imagick /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/imagick.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=yaml /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/yaml.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=scrypt /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/scrypt.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=zstd /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/zstd.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=brotli /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/brotli.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=lz4 /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/lz4.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=snappy /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/snappy.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=xdebug /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/
COPY --from=mongodb /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/mongodb.so /usr/local/lib/php/extensions/no-debug-non-zts-${PHP_API}/

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
