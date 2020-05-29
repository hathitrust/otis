# frozen_string_literal: true

require 'test_helper'
require 'action_mailer/test_helper'

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

  test 'index should have table headings matching status badges' do
    sign_in!
    get ht_approval_requests_url

    %w[Sent Approved Renewed].each do |status|
      assert_select 'th', {text: status}
    end
  end

  test 'should add requests and link to approver' do
    sign_in!
    assert_equal 0, HTApprovalRequest.count
    post ht_approval_requests_url, params: {ht_users: [@user1.email, @user2.email], submit_requests: true}
    assert_response :redirect
    follow_redirect!
    assert_equal 2, HTApprovalRequest.count
    assert_match 'Added', flash[:notice]
    assert_not_nil assigns(:reqs)
    assert_equal 'index', @controller.action_name
    assert_select "a[href='#{edit_ht_approval_request_path(@user1.approver)}']"
  end

  test 'should get index page and fail to submit zero-length request list' do
    sign_in!
    post ht_approval_requests_url, params: {submit_requests: true}
    assert_response :redirect
    follow_redirect!
    assert_not_nil assigns(:reqs)
    assert_empty assigns(:reqs)
    assert_match 'No users selected', flash[:alert]
    assert_equal 'index', @controller.action_name
  end

  test 'should get index page and fail to submit approval request for unknown user' do
    sign_in!
    post ht_approval_requests_url, params: {ht_users: ['nobody@nowhere.org'], submit_requests: true}
    assert_response :redirect
    follow_redirect!
    assert_not_nil assigns(:reqs)
    assert_empty assigns(:reqs)
    assert_match "Couldn't find HTUser", flash[:alert]
    assert_equal 'index', @controller.action_name
  end
end

class HTApprovalRequestControllerEditTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'approver@example.com')
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver)
  end

  test 'should get edit page' do
    sign_in!
    get edit_ht_approval_request_url @user.approver
    assert_response :success
    assert_not_nil assigns(:reqs)
    assert_equal 'edit', @controller.action_name
  end

  test 'edit page should not contain approval link' do
    sign_in!
    get edit_ht_approval_request_url @user.approver
    assert_no_match %r{/approve/}, response.body
  end

  test 'edit page has textarea for email' do
    sign_in!
    get edit_ht_approval_request_url @user.approver
    assert_select "form textarea[name='email_body']"
  end

  test 'edit page textarea has default email' do
    sign_in!
    get edit_ht_approval_request_url @user.approver
    assert_select "form textarea[name='email_body']" do |e|
      assert_match 'reauthorize', e.text
    end
  end

  test 'edit page textarea does not have user table' do
    sign_in!
    get edit_ht_approval_request_url @user.approver
    assert_select "form textarea[name='email_body']" do |e|
      assert_no_match @user.email, e.text
    end
  end

  test 'edit page shows user table below preview' do
    sign_in!
    get edit_ht_approval_request_url @user.approver
    assert_match %r{</textarea>.*#{@user.email}}m, response.body
  end
end

class HTApprovalRequestControllerUpdateTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'approver@example.com')
    @req = create(:ht_approval_request, userid: @user.email, approver: @user.approver)
  end

  def patch_approval_request(approver = @user.approver, params: {})
    sign_in!
    patch ht_approval_request_url approver, params: params
    assert_response :redirect
    assert_equal 'update', @controller.action_name
    follow_redirect!
  end

  test 'should use provided email body' do
    test_text = Faker::Lorem.paragraph

    patch_approval_request params: { email_body: test_text }

    ActionMailer::Base.deliveries.first.body.parts.each do |part|
      assert_match test_text, part.to_s
    end
  end

  test 'should send mail' do
    patch_approval_request

    assert ActionMailer::Base.deliveries.size
  end

  test 'should update request status' do
    patch_approval_request

    assert_not_nil @req.reload.sent
    assert_not_nil @req.reload[:token_hash]
    assert_equal 'show', @controller.action_name
  end

  test 'should fail to submit mail for non-approver' do
    patch_approval_request @user.email

    assert_not_nil assigns(:reqs)
    assert_equal 0, ActionMailer::Base.deliveries.size
    assert_empty assigns(:reqs)
    assert_match 'at least one', flash[:alert]
    assert_equal 'show', @controller.action_name
  end
end

class HTApprovalRequestControllerShowTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:ht_user, approver: 'approver@example.com')
  end

  test 'should get show page' do
    sign_in!
    get ht_approval_request_url @user.approver

    assert_response :success
    assert_not_nil assigns(:reqs)
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
    assert_equal Date.parse(@req.reload.sent).to_s, Date.parse(Time.zone.now.to_s).to_s
  end
end

class HTApprovalRequestControllerBatchRenewalTest < ActionDispatch::IntegrationTest
  def setup
    @user1 = create(:ht_user, approver: 'approver@example.com')
    @user2 = create(:ht_user, approver: 'approver@example.com')
    @req1 = create(:ht_approval_request, userid: @user1.email, approver: @user1.approver, sent: Time.now - 30.days, received: Time.now - 1.day, renewed: nil)
    @req2 = create(:ht_approval_request, userid: @user2.email, approver: @user2.approver, sent: Time.now - 30.days, received: Time.now - 1.day, renewed: nil)
  end

  test 'should get index after renewing 2 users' do
    sign_in!
    assert_equal 2, HTApprovalRequest.where(renewed: nil).count
    post ht_approval_requests_url, params: {ht_users: [@user1.email, @user2.email], submit_renewals: true}
    assert_response :redirect
    follow_redirect!
    assert_match 'Renewed', flash[:notice]
    assert_not_nil assigns(:renewed_users)
    assert_equal 'index', @controller.action_name
    assert @req1.reload.renewed?
    assert @req2.reload.renewed?
    assert_equal 0, HTApprovalRequest.where(renewed: nil).count
    assert_match 'class="success"', @response.body
  end

  test 'should get index page and fail to submit zero-length renewal list' do
    sign_in!
    assert_equal 2, HTApprovalRequest.where(renewed: nil).count
    post ht_approval_requests_url, params: {submit_renewals: true}
    assert_response :redirect
    follow_redirect!
    assert_match 'No users selected', flash[:alert]
    assert_equal 'index', @controller.action_name
    assert_equal 2, HTApprovalRequest.where(renewed: nil).count
  end

  test 'should not renew if no existing request' do
    sign_in!
    @user3 = create(:ht_user)
    expires = @user3.expires
    post ht_approval_requests_url, params: {ht_users: [@user3.email], submit_renewals: true}
    assert_response :redirect
    follow_redirect!

    @user3.reload
    assert_equal(expires, @user3.expires)
    assert_match 'No approved request', flash[:alert]
  end
end
