# frozen_string_literal: true

require "test_helper"

class HTApprovalRequestTest < ActiveSupport::TestCase
  def presenter(req)
    HTApprovalRequestPresenter.new(req)
  end

  test "select for renewal checkbox" do
    req = build(:ht_approval_request, :approved)
    assert_match("checkbox", presenter(req).select_for_renewal_checkbox)
  end

  test "no select for renewal checkbox" do
    req = build(:ht_approval_request, :renewed)
    assert_equal("", presenter(req).select_for_renewal_checkbox)
  end

  test "userid link has label" do
    req = build(:ht_approval_request, :approved)
    assert_match("label", presenter(req).userid_link(label: true))
  end

  test "userid link has no label even if allowed" do
    req = build(:ht_approval_request, :renewed)
    assert_no_match("label", presenter(req).userid_link(label: true))
  end

  test "userid link has no label" do
    req = build(:ht_approval_request, :approved)
    assert_no_match("label", presenter(req).userid_link(label: false))
  end

  test "userid link" do
    req = build(:ht_approval_request)
    assert_match("a href=\"/ht_users/#{req.userid}\"", presenter(req).userid_link)
  end

  test "approver link" do
    req = build(:ht_approval_request)
    assert_match("a href=\"/ht_approval_requests/#{req.approver}/edit\"", presenter(req).approver_link)
  end
end

class HTApprovalRequestPresenterBadgeTest < ActiveSupport::TestCase
  def badge(req)
    HTApprovalRequestPresenter.new(req).badge
  end

  test "approved badge" do
    req = build(:ht_approval_request, :approved)
    assert_equal(:approved, req.renewal_state)
    assert_not_nil badge(req)
    assert_match "Approved", badge(req)
  end

  test "expired badge" do
    req = build(:ht_approval_request, :expired)
    assert_equal(:expired, req.renewal_state)
    assert_not_nil badge(req)
    assert_match "Expired", badge(req)
  end

  test "sent badge" do
    req = build(:ht_approval_request, :sent)
    assert_equal(:sent, req.renewal_state)
    assert_not_nil badge(req)
    assert_match "Sent", badge(req)
  end

  test "unsent badge" do
    req = build(:ht_approval_request, :unsent)
    assert_equal(:unsent, req.renewal_state)
    assert_not_nil badge(req)
    assert_match "Unsent", badge(req)
  end
end
