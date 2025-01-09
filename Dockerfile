FROM ruby:3.1
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  nodejs \
  netcat-traditional

RUN gem install bundler
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -d /usr/src/app -u $UID -g $GID -o -s /bin/bash $UNAME
RUN mkdir -p /gems && chown $UID:$GID /gems
COPY --chown=$UID:$GID Gemfile* /usr/src/app/
WORKDIR /usr/src/app
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_ENV production
ENV BUNDLE_PATH /gems
RUN bundle install
COPY --chown=$UID:$GID --chmod=664 . /usr/src/app/*
USER $UNAME

CMD ["sh", "-c", "bin/rails assets:precompile && bin/rails s"]

LABEL org.opencontainers.image.source="https://github.com/hathitrust/otis"
