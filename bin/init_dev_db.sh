#!/bin/bash

export RAILS_ENV=development
# SKIP_TEST_DATABASE prevents the idiotic default behavior of the Rake database tasks
# (i.e., operating on both development and test databases).
# See https://stackoverflow.com/a/50254871
export SKIP_TEST_DATABASE=1
bundle exec rake db:drop
bundle exec rake db:create
# Break up db:reset to add the keycard & checkpoint schema at the right time
bundle exec rake keycard:migrate
bundle exec rake checkpoint:migrate
bundle exec rake db:schema:load
bundle exec rake db:seed
bundle exec rake otis:migrate_users
