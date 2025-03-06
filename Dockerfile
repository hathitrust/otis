FROM ruby:3.4 AS base

ARG UNAME=app
ARG UID=1000
ARG GID=1000

ENV BUNDLE_PATH /gems

################################################################################
# DEVELOPMENT                                           								       # 
################################################################################
FROM base AS development

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  nodejs \
  npm

WORKDIR /usr/src/app
RUN gem install bundler

################################################################################
# PRODUCTION                                                                   #
################################################################################
FROM base AS production

ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_ENV production
# FIXME: duplicate, see line 7
ENV BUNDLE_PATH /gems

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /usr/src/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p /gems && chown $UID:$GID /gems

USER $UNAME
WORKDIR /usr/src/app

COPY Gemfile* /usr/src/app/
RUN bundle install

COPY --chown=app:app . /usr/src/app

RUN npm ci
RUN npm run build

CMD ["sh", "-c", "bin/rails assets:precompile && bin/rails s"]

LABEL org.opencontainers.image.source="https://github.com/hathitrust/otis"
