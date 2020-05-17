# frozen_string_literal: true

require 'test_helper'

class HTApprovalRequestPresenterTest < ActiveSupport::TestCase
  test '#badge' do
    req = build(:ht_approval_request)
    presenter = HTApprovalRequestPresenter.new(req)
    assert_not_nil presenter.badge
  end
end
