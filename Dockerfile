FROM ruby:3.1 AS base

ARG UNAME=app
ARG UID=1000
ARG GID=1000

ENV BUNDLE_PATH /gems

FROM base AS development

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  nodejs \
  netcat-traditional

WORKDIR /usr/src/app
RUN gem install bundler

FROM base AS production

ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_ENV production
ENV BUNDLE_PATH /gems

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /usr/src/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p /gems && chown $UID:$GID /gems

USER $UNAME
WORKDIR /usr/src/app

COPY Gemfile* /usr/src/app/
RUN bundle install

COPY --chown=app:app . /usr/src/app

CMD ["sh", "-c", "bin/rails assets:precompile && bin/rails s"]

LABEL org.opencontainers.image.source="https://github.com/hathitrust/otis"
