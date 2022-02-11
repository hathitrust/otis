# frozen_string_literal: true

require "test_helper"

class SessionControllerTest < ActionDispatch::IntegrationTest
  test "should get login URL" do
    get login_url
    assert_response :redirect
    assert_redirected_to %r{/Shibboleth\.sso/}
  end

  test "login succeeds for known user" do
    post login_as_url, params: {username: "admin@default.invalid"}
    assert_response :redirect
    assert_redirected_to root_url(locale: I18n.locale)
  end

  test "login fails (eventually) for unknown user" do
    post login_as_url, params: {username: "nobody_whatsoever@example.com"}
    assert_response :redirect
    follow_redirect!
    assert_response 403
  end

  test "logout succeeds" do
    sign_in!
    post logout_url
    assert_response :redirect
    assert_redirected_to root_url(locale: I18n.locale)
  end
end
