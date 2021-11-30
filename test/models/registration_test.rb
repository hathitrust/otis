# frozen_string_literal: true

require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "factory builds a valid registration" do
    assert build(:registration).valid?
  end
end
