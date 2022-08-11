# frozen_string_literal: true

require "simplecov"
require "rake"
require "w3c_validators"
require "capybara"
require "selenium-webdriver"

SimpleCov.start "rails" do
  # Keep code only used with test environment from muddying the waters.
  add_filter "migrate_users.rake"
end

Capybara.server_host = "0.0.0.0"
Capybara.app_host = "http://#{ENV.fetch("HOSTNAME")}:#{Capybara.server_port}"
Selenium::WebDriver.logger.ignore(:browser_options)

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require_relative "fake_form"
require "rails/test_help"

Services.register(:whois) do
  Class.new do
    def lookup(ip)
      if ENV["SIMULATE_WHOIS_FAILURE"]
        raise SocketError, "getaddrinfo: Temporary failure in name resolution"
      end
      "TOTALLY LEGIT WHOIS for #{ip}"
    end
  end.new
end

def sign_in!(username: "admin@default.invalid")
  post login_as_url, params: {username: username}
end

def check_w3c_errs
  skip "Skipping W3C test" unless ENV["W3C_VALIDATION"]

  yield
  sleep 1
  assert_equal [], W3CValidators::NuValidator.new.validate_text(@response.body).errors
end

def fake_shib_id
  "#{Faker::Internet.url}!#{Faker::Internet.url}!#{SecureRandom.urlsafe_base64 16}"
end

Keycard::DB.migrate!
Checkpoint::DB.migrate!

load File.expand_path("lib/tasks/migrate_users.rake", Rails.root)
Rake::Task.define_task(:environment)
Rake::Task["otis:migrate_users"].invoke

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
