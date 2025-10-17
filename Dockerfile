FROM ruby:3.4 AS base

ARG UNAME=app
ARG UID=1000
ARG GID=1000

ENV BUNDLE_PATH=/gems

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  nodejs \
  npm \
  rclone

################################################################################
# DEVELOPMENT                                           								       # 
################################################################################
FROM base AS development

WORKDIR /usr/src/app
RUN gem install bundler

################################################################################
# PRODUCTION                                                                   #
################################################################################
FROM base AS production

ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_ENV=production
ENV RCLONE_CONFIG_PATH=/usr/src/app/config/rclone.conf

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /usr/src/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN chmod 755 /usr/src/app
RUN mkdir -p /gems && chown $UID:$GID /gems

USER $UNAME
WORKDIR /usr/src/app

COPY --chown=app:app . /usr/src/app
RUN bundle install

RUN npm ci
RUN npm run build

CMD ["sh", "-c", "bin/rails s"]

LABEL org.opencontainers.image.source="https://github.com/hathitrust/otis"
