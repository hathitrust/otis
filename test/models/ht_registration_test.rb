# frozen_string_literal: true

require "test_helper"

class HTRegistrationTest < ActiveSupport::TestCase
  test "factory builds a valid ht_registration" do
    assert build(:ht_registration).valid?
  end

  test "#resource_type" do
    assert_equal :ht_registration, build(:ht_registration).resource_type
  end

  test "#resource_id" do
    reg = build(:ht_registration)
    assert_equal reg.id, reg.resource_id
  end

  test "#env with valid JSON" do
    reg = build(:ht_registration, env: '{"something":"something_else"}')
    assert reg.env
  end

  test "#env with bogus JSON" do
    reg = build(:ht_registration, env: '{"something"}')
    assert_equal({}, reg.env)
  end
end
