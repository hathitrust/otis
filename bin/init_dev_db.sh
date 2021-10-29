#!/bin/bash

export RAILS_ENV=development
bin/wait-for mariadb-dev:3306 mariadb-test:3306
bundle exec rake db:drop
bundle exec rake db:create
# Break up db:reset to add the keycard & checkpoint schema at the right time
bundle exec rake keycard:migrate
bundle exec rake checkpoint:migrate
bundle exec rake db:schema:load
bundle exec rake db:seed
bundle exec rake otis:migrate_users
