# frozen_string_literal: true

require 'test_helper'

class HTApprovalRequestTest < ActiveSupport::TestCase
  test 'validation passes' do
    assert build(:ht_approval_request).valid?
  end

  test 'must have non-nil approver' do
    assert_not build(:ht_approval_request, approver: nil).valid?
  end

  test 'must have non-nil user' do
    assert_not build(:ht_approval_request, userid: nil).valid?
  end

  test 'sent must come before received' do
    assert_not build(:ht_approval_request, sent: Time.now, received: Time.now - 1).valid?
  end

  test 'a newly-sent request is not expired and not renewed' do
    assert_not build(:ht_approval_request, sent: Time.now).expired?
    assert_not build(:ht_approval_request, sent: Time.now).renewed.present?
  end

  test 'an old request is expired after a week' do
    assert build(:ht_approval_request, sent: (Time.now - 2.week)).expired?
  end

  test 'hashed token matches token after setting sent' do
    req = build(:ht_approval_request)

    token = req.token
    req.sent = Time.now

    assert_equal(HTApprovalRequest.digest(token), req.token_hash)
  end

  test 'resending expired request resets hash' do
    req = build(:ht_approval_request, :expired)

    token = req.token
    req.sent = Time.now

    assert_equal(HTApprovalRequest.digest(token), req.token_hash)
  end
end

class HTApprovalRequestUniquenessTest < ActiveSupport::TestCase
  def setup
    @active = create(:ht_approval_request, approver: 'nobody@example.com', userid: 'active@example.com', renewed: nil)
    @inactive = create(:ht_approval_request, approver: 'nobody@example.com', userid: 'inactive@example.com', renewed: Faker::Time.backward)
  end

  test 'user can have only one active approval request' do
    assert_not build(:ht_approval_request, userid: 'active@example.com').valid?
    assert build(:ht_approval_request, userid: 'inactove@example.com').valid?
  end
end
