# frozen_string_literal: true

require 'test_helper'

class HTInstitutionresenterTest < ActiveSupport::TestCase
  test 'disabled badge' do
    req = build(:ht_institution, :disabled)
    assert_not_nil HTInstitutionPresenter.badge_for(req)
    assert_match 'Disabled', HTInstitutionPresenter.badge_for(req)
  end

  test 'enabled badge' do
    req = build(:ht_institution, :enabled)
    assert_not_nil HTInstitutionPresenter.badge_for(req)
    assert_match 'Enabled', HTInstitutionPresenter.badge_for(req)
  end

  test 'private badge' do
    req = build(:ht_institution, :private)
    assert_not_nil HTInstitutionPresenter.badge_for(req)
    assert_match 'Private', HTInstitutionPresenter.badge_for(req)
  end

  test 'social badge' do
    req = build(:ht_institution, :social)
    assert_not_nil HTInstitutionPresenter.badge_for(req)
    assert_match 'Social', HTInstitutionPresenter.badge_for(req)
  end
end
