# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

def sign_in!
  post login_as_url, params: { username: 'nobody@example.com' }
end

Keycard::DB.migrate!

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def create_test_ht_user(userid, iprestrict: '127.0.0.1', expires: '2020-09-30 16:03:09')
    HTUser.new(userid: userid, iprestrict: iprestrict, expires: expires)
  end
end
