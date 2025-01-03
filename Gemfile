# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

######################################
# SECURITY UPDATES                   #
######################################

# https://github.com/advisories/GHSA-5m2v-hc64-56h6
gem "rubyzip", "~> 2.0"

# https://github.com/advisories/GHSA-c3gv-9cxf-6f57
gem "loofah", "~> 2.19"

# ruby '3.0.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.1.7.9"
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem "puma", "~> 5.6"
# Use SCSS/SASS for stylesheets
gem "sassc-rails"
# Use Terser as compressor for JavaScript assets, previously used Uglifier
gem "terser"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 4.2"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false

# Removed as default gems in ruby 3.1
gem "net-smtp"
gem "net-pop"
gem "net-imap"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", "< 3.2", ">= 3.0.5"
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem "capybara", ">= 2.15", "< 4.0"
  gem "selenium-webdriver"
  # Easy installation and use of chromedriver to run system tests with Chrome
  # gem 'chromedriver-helper'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

##############################################################################
#
# Otis
#
##############################################################################
gem "autoprefixer-rails"
gem "bootstrap", "~> 5.3"
gem "bootstrap-icons"
gem "jquery-rails"
gem "ckeditor"
gem "whois"
gem "whois-parser"
gem "accept_language"
gem "flag-icons-rails"
gem "rails-i18n", "~> 6.0.0"
gem "maxmind-geoip2"
gem "jira-ruby"
gem "ransack"
gem "kaminari"

gem "canister"
gem "ettin"
gem "keycard", github: "mlibrary/keycard"
gem "checkpoint"

# Use MySQL as the database for Active Record
gem "mysql2"
gem "dotenv-rails"

# Freeze Sequel version number because of Checkpoint prepared statement issues
gem "sequel", "5.52.0"

group :development, :test do
  gem "byebug"
  gem "standard"
  # parser should be >= the current Ruby version to avoid warnings
  gem "parser", ">= 3.1.6"
  gem "pry"
  gem "pry-byebug", ">= 3.9.0"
  gem "sqlite3"
  gem "faker"
  gem "factory_bot_rails"
  gem "simplecov"
  gem "simplecov-lcov"
  gem "i18n-tasks"
end

group :test do
  gem "rails-controller-testing"
  gem "w3c_validators"
end
