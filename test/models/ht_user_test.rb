# frozen_string_literal: true

require 'test_helper'

class HTUserTest < ActiveSupport::TestCase
  test 'iprestrict validation passes' do
    user = HTUser.new(userid: 'user', iprestrict: '127.0.0.1')
    assert user.valid?
  end

  test 'iprestrict validation fails' do
    user = HTUser.new(userid: 'user', iprestrict: '127.0.0.1.1')
    assert_not user.valid?
  end

  test 'iprestrict to English' do
    assert_equal HTUser.human_attribute_name(:iprestrict), 'IP Restriction'
  end
  
  test 'iprestrict escaping and unescaping' do
    user = HTUser.new(userid: 'user', iprestrict: '127.0.0.1')
    assert_equal user[:iprestrict], '^127\.0\.0\.1$'
    assert_equal user.iprestrict, '127.0.0.1'
  end
end
