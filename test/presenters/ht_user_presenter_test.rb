# frozen_string_literal: true

require 'test_helper'

class HTUserPresenterTest < ActiveSupport::TestCase
  test '#badge with approval request displays a badge' do
    user = HTUserPresenter.new(create(:ht_user))
    create(:ht_approval_request, userid: user.email)
    assert_not_nil user.badge
    assert_match 'span', user.badge
  end

  test '#badge without approval request is blank' do
    user = HTUserPresenter.new(create(:ht_user))
    assert_not_nil user.badge
    assert_match '', user.badge
  end
end
