# frozen_string_literal: true

require "test_helper"

class HTApprovalRequestTest < ActiveSupport::TestCase
  test "validation passes" do
    assert build(:ht_approval_request).valid?
  end

  test "must have non-nil approver" do
    assert_not build(:ht_approval_request, approver: nil).valid?
  end

  test "must have non-nil user" do
    assert_not build(:ht_approval_request, userid: nil).valid?
  end

  test "sent must come before received" do
    assert_not build(:ht_approval_request, sent: Time.zone.now, received: Time.zone.now - 1).valid?
  end

  test "a newly-sent request is not expired and not renewed" do
    assert_not build(:ht_approval_request, sent: Time.zone.now).expired?
    assert_not build(:ht_approval_request, sent: Time.zone.now).renewed.present?
  end

  test "an old request is expired after a week" do
    assert build(:ht_approval_request, sent: (Time.zone.now - 2.week)).expired?
  end

  test "hashed token matches token after setting sent" do
    req = build(:ht_approval_request)

    token = req.token
    req.sent = Time.now

    assert_equal(HTApprovalRequest.digest(token), req.token_hash)
  end

  test "resending expired request resets hash" do
    req = build(:ht_approval_request, :expired)

    token = req.token
    req.sent = Time.now

    assert_equal(HTApprovalRequest.digest(token), req.token_hash)
  end

  test "has correct Checkpoint attributes" do
    req = create(:ht_approval_request, :expired)
    assert_equal :ht_approval_request, req.resource_type
    assert_equal req.id, req.resource_id
  end

  test "most_recent finds most recent or most incomplete" do
    long_ago = Faker::Time.backward
    @active_user = create(:ht_user)
    create(:ht_approval_request, ht_user: @active_user, sent: long_ago, received: long_ago, renewed: long_ago)
    create(:ht_approval_request, ht_user: @active_user, sent: long_ago, received: long_ago, renewed: long_ago)
    req = create(:ht_approval_request, ht_user: @active_user, sent: nil, token_hash: nil)
    latest = HTApprovalRequest.most_recent(@active_user).first
    assert_equal(req, latest)
  end
end

class HTApprovalRequestUniquenessTest < ActiveSupport::TestCase
  def setup
    @active_user = create(:ht_user)

    create(:ht_approval_request,
      approver: "nobody@example.com",
      renewed: nil,
      ht_user: @active_user)

    @inactive_user = create(:ht_user)

    create(:ht_approval_request,
      approver: "nobody@example.com",
      renewed: Faker::Time.backward,
      ht_user: @inactive_user)
  end

  test "user can have only one active approval request" do
    assert_not build(:ht_approval_request, ht_user: @active_user).valid?
    assert build(:ht_approval_request, ht_user: @inactive_user).valid?
  end
end
