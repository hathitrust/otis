# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "rails", "~> 8.0"

# Use Puma as the app server
gem "puma"
# Use SCSS/SASS for stylesheets
gem "sassc-rails"
# Use Terser as compressor for JavaScript assets, previously used Uglifier
gem "terser"

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

gem "coffee-rails"
gem "ostruct"
gem "csv"

group :development, :test do
  gem "standard"
  gem "debug"
  gem "faker"
  gem "factory_bot_rails"
  gem "simplecov"
  gem "simplecov-lcov"
  gem "i18n-tasks"
end

group :test do
  gem "rails-controller-testing"
end
