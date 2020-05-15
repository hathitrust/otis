# frozen_string_literal: true

require 'test_helper'

class ApprovalControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'approver@wherever.edu', expire_type: 'expiresannually', expires: Time.now)
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver, sent: Date.today - 1.day)
  end

  test 'succeeds approval by approver with email not known in advance' do
    sign_in! username: Faker::Internet.email
    get approve_url @req.token
    assert_response :success
    assert_equal 'new', @controller.action_name
    assert_match @req.userid, @response.body
    assert_match @req.approver, @response.body
    assert_in_delta(365, @user.reload.days_until_expiration, 1)
    assert_not_nil @req.reload.received
    assert_equal Date.parse(@req.reload.received).to_s, Date.today.to_s
  end

  test 'refuses to approve the same request a second time' do
    sign_in!
    get approve_url @req.token
    assert_response :success
    get approve_url @req.token
    assert_response :success
    assert_match 'no longer', @response.body
  end

#  test 'logs the approvers session'
end

class ApprovalControllerFailureTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'no_account@example.com')
    @user2 = create(:ht_user, approver: 'nobody@example.com')
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver, sent: Date.today - 2.day)
    @req2 = create(:ht_approval_request, userid: @user2.email, approver: @user2.approver, sent: Date.today - 2.week)
  end

  test 'gets 404 with nonsense token' do
    sign_in!
    get approve_url 'asdfghjkl'
    assert_response :not_found
  end

  test 'gets 404 with unsent approval' do
    unsent = create(:ht_approval_request)
    sign_in!
    get approve_url unsent.token
    assert_response :not_found
  end

  test 'fails approval of expired request' do
    sign_in!
    get approve_url @req2.token
    assert_response :success
    assert_match 'expired', @response.body
  end
end
