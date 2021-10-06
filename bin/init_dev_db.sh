#!/bin/bash

bin/wait-for mariadb-dev:3306
bundle exec rake keycard:migrate RAILS_ENV=development
bundle exec rake checkpoint:migrate RAILS_ENV=development
bundle exec rake db:schema:load
bundle exec rake db:seed
bundle exec rake otis:migrate_users RAILS_ENV=development
