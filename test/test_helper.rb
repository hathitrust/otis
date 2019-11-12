# frozen_string_literal: true

require 'simplecov'

SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

def sign_in!
  post login_as_url, params: { username: 'nobody@example.com' }
end

Keycard::DB.migrate!

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
