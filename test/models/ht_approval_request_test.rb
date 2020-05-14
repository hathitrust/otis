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

  test 'a newly-sent request is not expired' do
    assert_not build(:ht_approval_request, sent: Time.now).expired?
  end

  test 'an old request is expired after a week' do
    assert build(:ht_approval_request, sent: (Time.now - 2.week)).expired?
  end
end

class HTApprovalRequestUniquenessTest < ActiveSupport::TestCase
  def setup
    @existing = create(:ht_approval_request, approver: 'nobody@example.com', userid: 'user@example.com')
  end

  test '#active returns only active users' do
    assert_not build(:ht_approval_request, approver: 'somebody@example.com', userid: 'user@example.com').valid?
  end
end
