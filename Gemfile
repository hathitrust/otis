# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "rails", "~> 8.0"
gem "rails-i18n"

# Use Puma as the app server
gem "puma"

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
gem "accept_language"
gem "canister"
gem "checkpoint"
gem "csv"
gem "dotenv-rails"
gem "ettin"
gem "jira-ruby"
gem "kaminari"
gem "keycard", github: "mlibrary/keycard"
gem "maxmind-geoip2"
gem "mysql2"
gem "ostruct"
gem "ransack"
# Freeze Sequel version number because of Checkpoint prepared statement issues
gem "sequel", "5.52.0"
gem "whois"
gem "whois-parser"

group :development, :test do
  gem "debug"
  gem "factory_bot_rails"
  gem "faker"
  gem "i18n-tasks"
  gem "simplecov"
  gem "simplecov-lcov"
  gem "standard"
end

group :test do
  gem "rails-controller-testing"
end
