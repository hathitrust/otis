# frozen_string_literal: true

require "simplecov"
require "rake"
require "w3c_validators"

SimpleCov.start "rails"

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Back up db/schema.rb to db/otis_schema.rb if it hasn't been created yet so it
# doesn't get clobbered. Then load mariadb-test into db/schema.rb
# so the Rsils guts can autocreate the standard HT tables.
Rake::Task["otis:db:prepare_local_schema"].invoke

# The aforementioned Rails guts.
require "rails/test_help"

# Any locally-defined tables not in db-image get loaded into mariadb-test.
Rake::Task["otis:db:load_local_schema"].invoke

def w3c_errs(html)
  skip "Skipping W3C test" unless ENV["W3C_VALIDATION"]

  sleep 1
  W3CValidators::NuValidator.new.validate_text(html).errors
end

Keycard::DB.migrate!
Checkpoint::DB.migrate!

load File.expand_path("lib/tasks/migrate_users.rake", Rails.root)
Rake::Task["otis:migrate_users"].invoke

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end

def sign_in!(username: "admin@default.invalid")
  post login_as_url, params: {username: username}
end
