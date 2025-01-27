#!/bin/bash

export RAILS_ENV=test

bundle exec rake db:seed
bundle exec rake test:system
[ $? -eq 0 ] || exit $?
bundle exec rake otis:clear_database RAILS_ENV=test
