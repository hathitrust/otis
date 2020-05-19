# frozen_string_literal: true

require 'test_helper'

class HTApprovalRequestPresenterTest < ActiveSupport::TestCase
  test 'badge' do
    req = build(:ht_approval_request)
    assert_not_nil HTApprovalRequestPresenter.badge_for(req)
  end
end
