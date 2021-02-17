#!/bin/bash

export RAILS_ENV=test

bin/wait-for mariadb-test:3306
bundle exec rake test
