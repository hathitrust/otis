# frozen_string_literal: true

require 'test_helper'

class HTUserTest < ActiveSupport::TestCase
  test 'validation passes' do
    assert build(:ht_user).valid?
  end

  test 'iprestrict validation fails' do
    assert_not build(:ht_user, iprestrict: '127.0.0.1.1').valid?
  end

  test 'iprestrict to English' do
    assert_equal HTUser.human_attribute_name(:iprestrict), 'IP Restriction'
  end

  test 'iprestrict escaping and unescaping' do
    user = build(:ht_user, iprestrict: '127.0.0.1')
    assert_equal user[:iprestrict], '^127\.0\.0\.1$'
    assert_equal user.iprestrict, '127.0.0.1'
  end

  test 'iprestrict with whitespace' do
    user = build(:ht_user, iprestrict: ' 127.0.0.1 ')
    assert_equal user[:iprestrict], '^127\.0\.0\.1$'
    assert_equal user.iprestrict, '127.0.0.1'
  end

  test 'expires suppresses UTC suffix' do
    user = build(:ht_user)
    assert_no_match(/UTC$/, user.expires.to_s)
  end

  test 'expires validation rejects various bogative timestamps' do
    user = build(:ht_user, expires: '2020-21-01 00:00:00')
    assert_not user.valid?
    user.expires = '2020-01-91'
    assert_not user.valid?
    user.expires = '2020-01-01 99:99:99'
    assert_not user.valid?
    user.expires = 'now'
    assert_not user.valid?
    user.expires = nil
    assert_not user.valid?
  end
end

class HTUserActiveExpiredTest < ActiveSupport::TestCase
  def setup
    @active  = create(:ht_user, :active)
    @expired = create(:ht_user, :expired)
  end

  test '#active returns only active users' do
    assert_includes(HTUser.active, @active)
    assert_not_includes(HTUser.active, @expired)
  end

  test '#expired returns only expired users' do
    assert_includes(HTUser.expired, @expired)
    assert_not_includes(HTUser.expired, @active)
  end
end

class HTUserExpiringSoon < ActiveSupport::TestCase
  def setup
    @expiring_user = build(:ht_user, expires: Date.today + 10)
    @expired_user  = build(:ht_user, expires: Date.today - 10)
    @safe_user     = build(:ht_user, expires: Date.today + 100)
  end

  # Do assert_in_delta because we're getting a full timestamp but
  # rounding to days
  test '#days_until_expiration' do
    assert_in_delta(10, @expiring_user.days_until_expiration, 1)
    assert_in_delta(-10, @expired_user.days_until_expiration, 1)
    assert_in_delta(100, @safe_user.days_until_expiration, 1)
  end

  test '#expiring_soon is correct for those in and outside the range' do
    assert(@expiring_user.expiring_soon?)
    assert_not(@expired_user.expiring_soon?)
    assert_not(@safe_user.expiring_soon?)
  end

  test 'Expiration date can be set via #expires' do
    user = build(:ht_user, expires: Date.today - 10)
    assert user.expired?
    assert user.expiration_date.expired?

    user.expires = Date.today + 100
    assert_not user.expired?
    assert_not user.expiration_date.expired?
  end

  test 'Extend date by default period' do
    initial_date = '2019-01-01'
    u1 = build(:ht_user, expires: initial_date, expire_type: 'expirescustom60')
    u1.extend_by_default_period!
    assert_equal Date.parse(initial_date) + 60, u1.expires.to_date
  end
end
