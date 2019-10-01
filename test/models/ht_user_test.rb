# frozen_string_literal: true

require 'test_helper'

class HTUserTest < ActiveSupport::TestCase
  test 'validation passes' do
    user = create_test_ht_user('user')
    assert user.valid?
  end

  test 'iprestrict validation fails' do
    user = create_test_ht_user('user', iprestrict: '127.0.0.1.1')
    assert_not user.valid?
  end

  test 'iprestrict to English' do
    assert_equal HTUser.human_attribute_name(:iprestrict), 'IP Restriction'
  end

  test 'iprestrict escaping and unescaping' do
    user = create_test_ht_user('user')
    assert_equal user[:iprestrict], '^127\.0\.0\.1$'
    assert_equal user.iprestrict, '127.0.0.1'
  end

  test 'iprestrict with whitespace' do
    user = create_test_ht_user('user', iprestrict: ' 127.0.0.1 ')
    assert_equal user[:iprestrict], '^127\.0\.0\.1$'
    assert_equal user.iprestrict, '127.0.0.1'
  end

  test 'expires suppresses UTC suffix' do
    user = create_test_ht_user('user')
    assert_no_match(/UTC$/, user.expires)
  end

  test 'expires validation rejects various bogative timestamps' do
    user = create_test_ht_user('user', expires: '2020-21-01 00:00:00')
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
