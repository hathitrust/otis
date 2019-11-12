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
    assert_no_match(/UTC$/, user.expires)
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
    @active = create(:ht_user, :active)
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
