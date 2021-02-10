FROM ruby:2.6
ARG UNAME=app
ARG UID=1000
ARG GID=1000

RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
  nodejs

# COPY Gemfile* /usr/src/app/
WORKDIR /usr/src/app
# 
ENV BUNDLE_PATH /gems
# 
RUN gem install bundler
# 
# COPY . /usr/src/app

CMD ["bin/rails", "s", "-b", "0.0.0.0"]


