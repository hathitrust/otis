# frozen_string_literal: true

require "test_helper"

class FakeShibControllerTest < ActionDispatch::IntegrationTest
  test "should get login form" do
    get fake_shib_url
    assert_equal "new", @controller.action_name
    assert_select "select[name=username]"
    assert_select "input[type=submit][name=login]"
  end
end
