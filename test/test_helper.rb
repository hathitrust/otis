# frozen_string_literal: true

require "simplecov"
require "simplecov-lcov"
require "rake"
require "capybara"
require "selenium-webdriver"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = "coverage/lcov.info"
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])

SimpleCov.start "rails" do
  # Keep code only used with test environment from muddying the waters.
  add_filter "clear_database.rake"
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

def fake_shib_id
  "#{Faker::Internet.url}!#{Faker::Internet.url}!#{SecureRandom.urlsafe_base64 16}"
end

Keycard::DB.migrate!
Checkpoint::DB.migrate!

# Loading them here seems to keep individual rake tests from clobbering coverage stats.
# Note: do not load any further individual tasks or they will be run twice.
Otis::Application.load_tasks
Rake::Task.define_task(:environment)
Rake::Task["otis:migrate_users"].invoke

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
