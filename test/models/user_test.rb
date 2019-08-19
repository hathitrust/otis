# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'find_by_username accepts known user' do
    assert_nothing_raised do
      User.find_by_username('nobody@example.com')
    end
  end

  test 'find_by_username raises for unknown user' do
    assert_raises ApplicationController::NotAuthorizedError do
      User.find_by_username('nobody_at_all@example.com')
    end
  end
end
