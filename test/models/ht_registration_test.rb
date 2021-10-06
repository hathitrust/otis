# frozen_string_literal: true

require "test_helper"

class HTRegistrationTest < ActiveSupport::TestCase
  test "basic math" do
    assert_equal(1, 1)
  end

  test "validation passes" do
    assert build(:ht_registration).valid?
  end
end
