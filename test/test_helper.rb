# frozen_string_literal: true

require 'simplecov'

SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

def sign_in!(username: 'nobody@example.com')
  post login_as_url, params: { username: username }
end

Keycard::DB.migrate!

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
end
