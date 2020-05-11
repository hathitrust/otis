# frozen_string_literal: true

require 'test_helper'

class ApprovalControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'nobody@example.com')
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver, sent: Date.today - 1.day)
  end

  test 'succeeds approval by approver' do
    sign_in!
    get approve_url @req.token
    assert_response :success
    assert_equal 'new', @controller.action_name
    assert_match @req.userid, @response.body
    assert_match @req.approver, @response.body
  end
end

class ApprovalControllerFailureTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'no_account@example.com')
    @user2 = create(:ht_user, approver: 'nobody@example.com')
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver, sent: Date.today - 2.day)
    @req2 = create(:ht_approval_request, userid: @user2.email, approver: @user2.approver, sent: Date.today - 2.week)
  end

  test 'fails approval by non-approver' do
    sign_in!
    get approve_url @req.token
    assert_response :forbidden
  end

  test 'fails approval of expired request' do
    sign_in!
    get approve_url @req2.token
    assert_response :success
    assert_match 'expired', @response.body
  end
end
