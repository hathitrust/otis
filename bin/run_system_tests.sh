#!/bin/bash

export RAILS_ENV=test

bin/wait-for mariadb-test:3306
bin/wait-for chrome-server:4444
bundle exec rake db:seed
bundle exec rake test:system
bundle exec rake otis:clear_database RAILS_ENV=test
