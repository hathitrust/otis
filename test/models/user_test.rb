# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "authenticate_by_auth_token raises" do
    assert_raises StandardError do
      User.authenticate_by_auth_token("id")
    end
  end

  test "authenticate_by_id returns a User" do
    user = User.authenticate_by_id("id")
    assert_instance_of User, user
    assert_equal user.id, "id"
  end

  test "authenticate_by_user_eid returns a User" do
    user = User.authenticate_by_user_eid("eid")
    assert_instance_of User, user
    assert_equal user.id, "eid"
  end

  test "authenticate_by_user_pid returns a User" do
    user = User.authenticate_by_user_pid("pid")
    assert_instance_of User, user
    assert_equal user.id, "pid"
  end

  test "new returns a User" do
    user = User.new("id")
    assert_instance_of User, user
    assert_equal user.id, "id"
  end

  test "identity returns something" do
    user = User.new("id")
    assert_equal user.identity, username: "id"
  end

  test "correct Checkpoint agent_type and agent_id" do
    user = User.new("id")
    assert_equal user.agent_type, :user
    assert_equal user.agent_id, "id"
  end
end
