# frozen_string_literal: true

require "test_helper"

class HTRegistrationTest < ActiveSupport::TestCase
  test "factory builds a valid ht_registration" do
    assert build(:ht_registration).valid?
  end
end
