# frozen_string_literal: true

require 'test_helper'

class HTUsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = create(:ht_user)
    @user2 = create(:ht_user)
  end

  test 'should get index' do
    sign_in!
    get ht_users_url
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 'index', @controller.action_name
    # assert_equal "application/x-www-form-urlencoded", @request.media_type
    assert_match 'Users', @response.body
    assert_match @user1.email, @response.body
    assert_match @user2.email, @response.body
  end

  test 'should get index with successful e-mail search' do
    sign_in!
    get ht_users_url, params: {email: @user1.email}
    assert_response :success
    assert_equal assigns(:users).count, 1
    assert_equal 'index', @controller.action_name
    assert_empty flash
    assert_match 'Users', @response.body
  end

  test 'should get index with unsuccessful e-mail search' do
    sign_in!
    get ht_users_url, params: {email: 'nobody@here.edu'}
    assert_response :success
    assert_equal assigns(:users).count, 0
    assert_equal 'index', @controller.action_name
    assert_match 'nobody', flash[:alert]
    assert_match 'Users', @response.body
  end

  test 'should get show page' do
    sign_in!
    get ht_users_url @user1
    assert_response :success
    assert_not_nil assigns(:users)
    assert_match @user1.email, @response.body
    assert_match @user1.institution, @response.body
  end

  test 'should get edit page' do
    sign_in!
    get edit_ht_user_url @user1
    assert_response :success
    assert_equal 'edit', @controller.action_name
  end

  test 'edit IP address succeeds' do
    sign_in!
    patch ht_user_url @user1, params: {'ht_user' => {'iprestrict' => '33.33.33.33'}}
    assert_response :redirect
    assert_equal 'update', @controller.action_name
    assert_not_empty flash[:notice]
    assert_redirected_to ht_user_path(@user1.email)
    follow_redirect!
    assert_match '33.33.33.33', @response.body
    assert_equal '^33\.33\.33\.33$', HTUser.find(@user1.email)[:iprestrict]
  end

  test 'edit IP address fails' do
    user = create(:ht_user, iprestrict: '127.0.0.2')
    sign_in!
    patch ht_user_url user, params: {'ht_user' => {'iprestrict' => '33.33.33.blah'}}
    assert_response :success
    assert_equal 'update', @controller.action_name
    assert_match 'IPv4', flash[:alert]
    assert_match '127.0.0.2', @response.body
  end

  test 'updating expiration for mfa user retains nil iprestrict' do
    user = create(:ht_user_mfa)
    sign_in!
    patch ht_user_url user, params: {'ht_user' => {'iprestrict' => '', 'expires' => Date.today.to_s}}
    assert_redirected_to ht_user_path(user.email)
    assert_nil HTUser.find(user.email)[:iprestrict]
  end

  test 'setting MFA unsets iprestrict' do
    user = create(:ht_user, :inst_mfa, mfa: false, iprestrict: '33.33.33.33')
    sign_in!
    patch ht_user_url user, params: {'ht_user' => {'iprestrict' => '', 'mfa' => true}}
    assert_redirected_to ht_user_path(user.email)
    assert HTUser.find(user.email)[:mfa]
    assert_nil HTUser.find(user.email)[:iprestrict]
  end

  test 'active users separated from expired users' do
    active  = create(:ht_user, :active)
    expired = create(:ht_user, :expired)

    sign_in!
    get ht_users_url

    assert_match(/Active Users.*#{active.email}.*Expired Users.*#{expired.email}/m, @response.body)
  end

  test 'users sorted by institution' do
    create(:ht_user, ht_institution: create(:ht_institution, name: 'Zebra College'))
    create(:ht_user, ht_institution: create(:ht_institution, name: 'Aardvark University'))

    sign_in!
    get ht_users_url

    assert_match(/Aardvark.*Zebra/m, @response.body)
  end

  test 'Expiring soon user marked' do
    # Make at least one user who's expiring soon
    create(:ht_user, email: 'user@nowhere.com', expires: (Date.today + 10).to_s)
    sign_in!
    get ht_users_url
    # look for the class name
    assert_match(/expiring-soon/m, @response.body)
  end

  test 'Editable fields present' do
    EDITABLE_FIELDS = %w[approver iprestrict expires].freeze
    create(:ht_user, id: 'test', email: 'user@nowhere.com', expires: (Date.today + 10).to_s)
    sign_in!
    get edit_ht_user_url id: 'test'
    EDITABLE_FIELDS.each do |ef|
      assert_match(/name="ht_user\[#{ef}\]"/, @response.body)
    end
  end

  test 'iprestrict disabled for MFA user' do
    create(:ht_user_mfa, id: 'test')
    sign_in!
    get edit_ht_user_url id: 'test'
    assert_select 'input#iprestrict_field' do |input|
      assert input.attr('disabled').present?
    end
  end

  test 'mfa not editable for user from institution without mfa available' do
    user = create(:ht_user)
    sign_in!
    patch ht_user_url user, params: {'ht_user' => {'mfa' => true}}
    assert_response :success
    assert_match 'Mfa', flash[:alert]
    assert_nil HTUser.find(user.email)[:mfa]
  end

  test 'mfa checkbox not present for institituion without MFA available' do
    create(:ht_user, id: 'test')
    sign_in!
    get edit_ht_user_url id: 'test'
    assert_select 'input#mfa_checkbox', 0
  end
end
