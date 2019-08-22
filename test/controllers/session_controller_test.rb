# frozen_string_literal: true

require 'test_helper'

class SessionControllerTest < ActionDispatch::IntegrationTest
  test 'should get login URL' do
    get login_url
    assert_response :success
  end

  test 'login succeeds for known user' do
    post login_as_url, params: { username: 'nobody@example.com' }
    assert_response :redirect
    assert_redirected_to root_path
  end

  test 'login fails (eventually) for unknown user' do
    post login_as_url, params: { username: 'nobody_at_all@example.com' }
    assert_response :redirect
    follow_redirect!
    assert_response 403
  end

  test 'logout succeeds' do
    sign_in!
    post logout_url
    assert_response :redirect
    assert_redirected_to root_path
  end
end
