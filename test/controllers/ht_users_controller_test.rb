# frozen_string_literal: true

require 'test_helper'

class HTUsersControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    sign_in!
    get ht_users_url
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 'index', @controller.action_name
    # assert_equal "application/x-www-form-urlencoded", @request.media_type
    assert_match 'Users', @response.body
    assert_match 'me@here.edu', @response.body
    assert_match 'him@there.com', @response.body
  end

  test 'should get index with successful e-mail search' do
    sign_in!
    get ht_users_url, params: { email: 'me@here.edu' }
    assert_response :success
    assert_equal assigns(:users).count, 1
    assert_equal 'index', @controller.action_name
    assert_empty flash
    assert_match 'Users', @response.body
  end

  test 'should get index with unsuccessful e-mail search' do
    sign_in!
    get ht_users_url, params: { email: 'nobody@here.edu' }
    assert_response :success
    assert_equal assigns(:users).count, 0
    assert_equal 'index', @controller.action_name
    assert_match 'nobody', flash[:alert]
    assert_match 'Users', @response.body
  end

  test 'should get show page' do
    sign_in!
    get ht_users_url 'me@here.edu'
    assert_response :success
    assert_not_nil assigns(:users)
    assert_match 'user1', @response.body
    assert_match 'Institution 1', @response.body
  end

  test 'should get edit page' do
    sign_in!
    get edit_ht_user_url 'me@here.edu'
    assert_response :success
    assert_equal 'edit', @controller.action_name
  end

  test 'edit IP address succeeds' do
    sign_in!
    patch ht_user_url 'me@here.edu', params: {'ht_user' => {'iprestrict' => '33.33.33.33'}}
    assert_response :redirect
    assert_equal 'update', @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_user_path('me@here.edu')
    follow_redirect!
    assert_match '33.33.33.33', @response.body
    assert_equal '^33\.33\.33\.33$', HTUser.find('me@here.edu')[:iprestrict]
  end

  test 'edit IP address fails' do
    sign_in!
    patch ht_user_url 'him@there.com', params: {'ht_user' => {'iprestrict' => '33.33.33.blah'}}
    assert_response :success
    assert_equal 'update', @controller.action_name
    assert_match 'IPv4', flash[:alert]
    assert_match '127.0.0.2', @response.body
  end
end
