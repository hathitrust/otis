# frozen_string_literal: true

require "simplecov"
require "rake"

SimpleCov.start "rails"

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

def sign_in!(username: "admin@default.invalid")
  post login_as_url, params: {username: username}
end

Keycard::DB.migrate!
Checkpoint::DB.migrate!

load File.expand_path("lib/tasks/migrate_users.rake", Rails.root)
Rake::Task.define_task(:environment)
Rake::Task["otis:migrate_users"].invoke

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
