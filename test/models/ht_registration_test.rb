# frozen_string_literal: true

require "test_helper"

class HTRegistrationTest < ActiveSupport::TestCase
  test "validation passes" do
    assert build(:ht_registration).valid?
  end
end
