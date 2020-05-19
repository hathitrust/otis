# frozen_string_literal: true

require 'test_helper'

class HTApprovalRequestControllerIndexTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = create(:ht_user, approver: 'approver@example.com')
    @user2 = create(:ht_user, approver: 'approver@example.com')
  end

  test 'should get index' do
    sign_in!
    get ht_approval_requests_url
    assert_response :success
    assert_not_nil assigns(:reqs)
    assert_equal 'index', @controller.action_name
  end

  test 'should get index after adding 2 requests' do
    sign_in!
    assert_equal 0, HTApprovalRequest.count
    get ht_approval_requests_url, params: {ht_users: [@user1.email, @user2.email], submit_req: true}
    assert_response :success
    assert_equal 2, HTApprovalRequest.count
    assert_not_nil assigns(:reqs)
    assert_equal 'index', @controller.action_name
  end

  test 'should get index page and fail to submit zero-length request list' do
    sign_in!
    get ht_approval_requests_url, params: {submit_req: true}
    assert_response :success
    assert_not_nil assigns(:reqs)
    assert_empty assigns(:reqs)
    assert_match 'No users selected', flash[:alert]
    assert_equal 'index', @controller.action_name
  end

  test 'should get index page and fail to submit approval request for unknown user' do
    sign_in!
    get ht_approval_requests_url, params: {ht_users: ['nobody@nowhere.org'], submit_req: true}
    assert_response :success
    assert_not_nil assigns(:reqs)
    assert_empty assigns(:reqs)
    assert_match 'Unknown user', flash[:alert]
    assert_equal 'index', @controller.action_name
  end
end

class HTApprovalRequestControllerShowTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = create(:ht_user, approver: 'approver@example.com')
    @user2 = create(:ht_user, approver: 'approver@example.com')
    @req = create(:ht_approval_request, userid: @user1.email, approver: @user1.approver)
  end

  test 'should get show page' do
    sign_in!
    get ht_approval_request_url @user1.approver
    assert_response :success
    assert_not_nil assigns(:reqs)
    assert_equal 'show', @controller.action_name
  end

  test 'should get edit page' do
    sign_in!
    get edit_ht_approval_request_url @user1.approver
    assert_response :success
    assert_not_nil assigns(:reqs)
    assert_equal 'edit', @controller.action_name
  end

  test 'should submit mail' do
    sign_in!
    patch ht_approval_request_url @user1.approver
    assert_response :redirect
    assert_equal 'update', @controller.action_name
    follow_redirect!
    assert_not_nil @req.reload.sent
    assert_not_nil @req.reload[:crypt]
    assert_equal 'show', @controller.action_name
  end

  test 'should fail to submit mail for non-approver' do
    sign_in!
    patch ht_approval_request_url @user1.email
    assert_response :redirect
    assert_equal 'update', @controller.action_name
    follow_redirect!
    assert_not_nil assigns(:reqs)
    assert_empty assigns(:reqs)
    assert_match 'at least one', flash[:alert]
    assert_equal 'show', @controller.action_name
  end
end

class HTApprovalRequestControllerResendTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'approver@example.com')
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver, sent: Time.now - 30.days)
  end

  test 'resending e-mail resets sent timestamp' do
    sign_in!
    patch ht_approval_request_url @user.approver
    follow_redirect!
    assert_equal Date.parse(@req.reload.sent).to_s, Date.today.to_s
  end
end
